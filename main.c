#include <stdio.h>
#include <fcntl.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <stdarg.h>
#include <time.h>
#include <sys/types.h>
#include <pwd.h>
#include <unistd.h>
#include <ctype.h>

#include "at.h"
#include "y.tab.h"

extern char **environ;

int notify = 0;
int debug = 0;

char *pgm;

void
abend(char *fmt, ...)
{
    va_list ptr;

    if ( fmt ) {
	va_start(ptr, fmt);
	fprintf(stderr, "%s: ", pgm);
	vfprintf(stderr, fmt, ptr);
	fputc('\n', stderr);
	va_end(ptr);
    }
    else
	fprintf(stderr, "usage: %s [-m] [-f file] when << job\n", pgm);
    exit(1);
}


int
plural(char *s)
{
    int len = strlen(s);

    return (len > 0) && (s[len-1] == 's');
}


static void
offset(atjobtime *at, struct tm *tm)
{
    if ( (at->offset == 1 && at->plural) || (at->offset != 1 && !at->plural) )
	abend("syntax error (pluralization)");
    
    switch (at->units) {
    case MINUTE:	tm->tm_min += at->offset;
			break;
    case HOUR:		tm->tm_hour += at->offset;
			break;
    case DAY:		tm->tm_mday += at->offset;
			break;
    case WEEK:		tm->tm_mday += 7 * at->offset;
			break;
    case MONTH:		tm->tm_mon += at->offset;
			break;
    case YEAR:		tm->tm_year += at->offset;
			break;
    }
}


static time_t
maketime(atjobtime *at)
{
    time_t now, madetime;
    struct tm *t;

    if ( at->hour > (at->pm  ? 12 : 24) )
	abend("incorrect time of day");
	
    if (at->pm == 2) at->hour += 12;

    time(&now);
    t = localtime(&now);

    if (debug & 0x04) {
	madetime = mktime(t);
	printf("now: %s", ctime(&madetime));
    }
    
    /*t->tm_sec = 0;*/
    t->tm_isdst = -1;

    if (at->hour >= 0) t->tm_hour = at->hour;
    if (at->minute >= 0) t->tm_min = at->minute;
    if (at->day > 0) t->tm_mday = at->day;
    if (at->month > 0) t->tm_mon = at->month-1;
    if (at->year > 0) t->tm_year = at->year - 1900;

    if (at->units)
	offset(at,t);

    switch (at->special) {
    case TODAY:	break;
    case DAYNAME:
		if ( t->tm_wday < at->offset )
		    t->tm_mday += (at->offset - t->tm_wday);
		else
		    t->tm_mday += 7 + (at->offset - t->tm_wday);
		break;
    case TOMORROW:
		t->tm_mday++;
		break;
    case TONIGHT:
		if ( (at->pm != 2) && (at->hour < 6) )
		    t->tm_mday ++;
		break;
    default:	madetime = mktime(t);
		if (madetime < now) {
		    if (at->year == 0) t->tm_year ++;
		    else  t->tm_mday ++;
		}
		break;
    }

    if ( (madetime = mktime(t)) < now )
	abend("cannot travel back in time");
    
    if ( debug & 0x08 )
	printf("%ld\n", madetime-now);
    return madetime;
}


void
savejob(time_t when)
{
    int c, i, fd;
    char *v, *r;
    char job[1+16+4+1];	/* 1 (id) + 16 (date) + 4 (extension) + 1 (0) */
    unsigned short seq = 0;
    FILE *output = 0 /* meaningless, but it shuts gcc the fuck up */;
    char *pwd;
    int size;

    if ( (pwd = malloc(size=1024)) == 0 )
	abend("%s", strerror(errno));

    while ( (getcwd(pwd,size) == 0) && (errno == ERANGE) ) {
	size *= 2;
	if ( (pwd = realloc(pwd, size)) == 0 )
	    abend("%s", strerror(errno));
    }

    if ( chdir(ATDIR) != 0 )
	abend("%s", strerror(errno));

    while (1) {
	if (sizeof(when) > 4)
	    snprintf(job, sizeof job, "a%016lx%04x", when, seq);
	else
	    snprintf(job, sizeof job, "a%08lx%04x", when, seq);

	if ( (fd = open(job, O_CREAT|O_EXCL|O_WRONLY, 0600)) != -1 )
	    break;
	if ( errno != EEXIST )
	    abend("%s", strerror(errno));
	else if ( ++seq == 0 )
	    abend("spool is full -- can't save job");
    }
    if ( (fchown(fd, getuid(), getgid()) == -1) || 
					((output = fdopen(fd, "w")) == 0) ) {
	unlink(job);
	abend("spool: %s", strerror(errno));
    }
    
    /* 
     * write out the environment
     */
    for (i=0; environ[i]; i++) {
	/* weed out tty-specific variables
	 */
	if ( strncmp(environ[i], "TERM=", 5) == 0 )
	    continue;
	if ( strncmp(environ[i], "TERMCAP=", 8) == 0 )
	    continue;
	if ( strncmp(environ[i], "DISPLAY=", 8) == 0 )
	    continue;
	if ( strncmp(environ[i], "_=", 2) == 0 )
	    continue;
	/* make certain that this is a valid environment
	 * variable in the form of name=<stuff>
	 */
	for (v=environ[i]; isalnum(*v); ++v)
	    ;
	if ( *v == '=' ) {
	    /* legitimate environment variable */
	    fwrite(environ[i], v-environ[i], 1, output);
	    fputc('=',output);
	    for (r=v+1; *r; ++r) {
		if ( isprint(*r) ) {
		    if ( !isalnum(*r) )
			fputc('\\', output);
		    fputc(*r, output);
		}
		else
		    fprintf(output, "'%c'", *r);
	    }
	    fprintf(output, "; export ");
	    fwrite(environ[i], v-environ[i], 1, output);
	    fputc('\n', output);
	}
    }

    fprintf(output, "cd %s || exit 1\n", pwd);

    size = 0;
    while ( (c = getchar()) != EOF )
	if ( fputc(c, output) == EOF ) {
	    fclose(output);
	    unlink(job);
	    abend("write error");
	}
	else size ++;
    fclose(output);
    if (size == 0)
	unlink(job);
    exit(0);
}


int
main(argc, argv)
char **argv;
{
    atjobtime at;
    time_t jobtime;
    int opt;
    int redirect = 0;

    pgm = basename(argv[0]);
    opterr = 1;
    
    while ( (opt = getopt(argc,argv, "d:f:m")) != EOF )
	switch (opt) {
	case 'd':
		debug = atoi(optarg);
		break;
	case 'm':
		notify = 1;
		break;
	case 'f':
		if ( redirect ) {
		    abend("too many -f options");
		    exit(1);
		}
		if ( freopen(optarg, "r", stdin) == 0 )
		    abend("%s", strerror(errno));
	default:
	    abend(0);
	}

    argc -= optind;
    argv += optind;

    if ( argc < 1 )
	abend(0);
       
    if ( yy_prepare(&at, argc, argv) <= 0 )
	abend("%s", strerror(errno));
    
    yyparse();	/* dies if it can't successfully parse the time */

    jobtime = maketime(&at);

    if ( debug & 0x01 )
	fprintf(stderr, "job: %s", ctime(&jobtime));
    if ( !(debug & 0x02) )
	savejob(jobtime);
    exit(0);
}
