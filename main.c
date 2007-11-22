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


static void
dump(atjobtime *a)
{
    if (a->mode == DATE) {
	fprintf(stderr, "<%d:%02d", a->hour, a->minute);
	if (a->pm >= 0)
	    fprintf(stderr," %s", a->pm ? "pm" : "am");
	switch (a->special) {
	case TODAY:
	    fprintf(stderr, " today");
	    break;
	case TONIGHT:
	    fprintf(stderr, " tonight");
	    break;
	case TOMORROW:
	    fprintf(stderr, " tomorrow");
	    break;
	case SOONEST:
	    fprintf(stderr, " soonest");
	    break;
	default:
	    fprintf(stderr, " %d.%d", a->day, a->month + 1);
	break;
	}
	if (a->year > 0)
	    fprintf(stderr, ".%d", a->year);
	fputc('>',stderr);
    }
    else {
	fputc('<',stderr);
	if (a->mode == EXACT_OFFSET)
	    fprintf(stderr,"%d:%02d %s, ",
		    a->hour,a->minute,
		    a->pm ? "pm":"am");
	fprintf(stderr, "offset=%d,units=%d%s>",
		a->offset,a->units,
		(a->mode==OFFSET)?"":",EXACT");
    }
    fputc('\n', stderr);
}


static void
offset(atjobtime *at, struct tm *tm)
{
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

    if (at->pm > 0) at->hour += 12;
    
    time(&now);
    t = localtime(&now);

    t->tm_sec = 0;
    t->tm_isdst = -1;

    switch (at->mode) {
    case DATE:
	    t->tm_hour = at->hour;
	    t->tm_min = at->minute;
	    t->tm_wday %= 7;
	    
	    switch (at->special) {
	    case TODAY:	break;
	    case WEEK:	t->tm_mday += (7+1)  - t->tm_wday;
			break;
	    case MONTH:	t->tm_mon ++;
			t->tm_mday = 1;
			break;
	    case YEAR:	t->tm_year ++;
			t->tm_mon = 0;
			t->tm_mday = 1;
			break;
	    case DAYNAME:
			if ( t->tm_wday < at->offset )
			    t->tm_mday += (at->offset - t->tm_wday);
			else
			    t->tm_mday += 7 - (at->offset - t->tm_wday);
			break;
	    case TOMORROW:
			t->tm_mday++;
			break;
	    case TONIGHT:
			if ( (at->pm <= 0) && (at->hour < 6) )
			    t->tm_mday ++;
			break;
	    case SOONEST:
			if ( mktime(t) < now )
			    t->tm_mday ++;
			break;
	    default:	t->tm_mday = at->day;
			if (at->month >= 0)
			    t->tm_mon = at->month;
			if ( at->year != -1 )
			    t->tm_year = at->year - 1900;
			else if ( mktime(t) < now )
			    t->tm_year ++;
			break;
	    }
	    break;
    case OFFSET:
	    t->tm_hour = at->hour;
	    t->tm_min = at->minute;
    case EXACT_OFFSET:
	    offset(at,t);
	    break;
    }
    madetime = mktime(t);

    if (madetime < now) {
	abend("cannot travel back in time\n");
	if ( debug & 0x01 )
	    dump(at);
	exit(1);
    }
    return madetime;
}


void
savejob(time_t when)
{
    int c, i, fd;
    char *v, *r;
    char job[1+16+4+1];	/* 1 (id) + 16 (date) + 4 (extension) + 1 (0) */
    unsigned short seq = 0;
    FILE *output;
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
	if (sizeof(when) == 4)
	    snprintf(job, sizeof job, "a%08x%04x", when, seq);
	else
	    snprintf(job, sizeof job, "a%016x%04x", when, seq);

	if ( (fd = open(job, O_CREAT|O_EXCL|O_WRONLY, 0600)) != -1 )
	    break;
	if ( errno != EEXIST )
	    abend("%s", strerror(errno));
	else if ( ++seq == 0 )
	    abend("spool is full -- can't save job");
    }

    if ( (output = fdopen(fd, "w")) == 0 )
	abend("spool: %s", strerror(errno));
    
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

    while ( (c = getchar()) != EOF )
	if ( fputc(c, output) == EOF ) {
	    fclose(output);
	    unlink(job);
	    abend("write error");
	}
    fclose(output);
    fchown(fd, geteuid(), getegid());
    exit(0);
}


int
main(argc, argv)
char **argv;
{
    atjobtime at;
    time_t jobtime;
    int i, opt;
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
	fprintf(stderr, "job time = %s", ctime(&jobtime));
    if ( debug & 0x02 )
	exit(0);
    savejob(jobtime);
}
