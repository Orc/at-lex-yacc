/*
 * at:   run a batch job at a given time (like go, but schedulable)
 */
#include <stdio.h>
#include <fcntl.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <stdarg.h>
#include <time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <pwd.h>
#include <unistd.h>
#include <ctype.h>
#ifdef HAVE_LIBGEN_H
#   include <libgen.h>
#endif

#include "at.h"
#include "y.tab.h"

/* carry around the environment so the batch job can use it.
 */
extern char **environ;

static int notify = 0;		/* notify the user when the job finishes */
static int debug = 0;		/* various debugging flags for development */

static char *pgm;


#ifndef HAVE_BASENAME
/*
 * get the non-directory part of a pathname
 */
static char *
basename(char *p)
{
    char *ret = strrchr(p, '/');

    return ret ? (1+ret) : p;
}
#endif


/*
 * whine bitterly about something, then die a horrible death
 */
static void
abend(char *fmt, ...)
{
    va_list ptr;

    va_start(ptr, fmt);
    fprintf(stderr, "%s: ", pgm);
    vfprintf(stderr, fmt, ptr);
    fputc('\n', stderr);
    va_end(ptr);
    exit(1);
}


/*
 * spit out a usage message, then die
 */
static void
usage()
{
    fprintf(stderr, "usage: %s [-m] [-f file] when << job\n", pgm);
    exit(1);
}


/*
 * write a job into the at spool
 */
static void
savejob(time_t when)
{
    int c, i, fd;
    char *v, *r;
    char job[1+16+4+1];	/* 1 (id) + 16 (date) + 4 (extension) + 1 (0) */
    unsigned short seq = 0;
    FILE *output = 0 /* meaningless, but it shuts gcc the fuck up */;
    char *pwd;
    struct passwd *user = getpwuid(getuid());
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
	snprintf(job, sizeof job, "c%05lx%08lx", seq, when/60);

	if ( (fd = open(job, O_CREAT|O_EXCL|O_WRONLY, 0600)) != -1 )
	    break;
	if ( errno != EEXIST )
	    abend("%s", strerror(errno));
	else if ( ++seq == 0 )
	    abend("spool is full -- can't save job");
    }
    if ( (fchown(fd, getuid(), getgid()) == -1)
	   || ((output = fdopen(fd, "w")) == 0) ) {
	unlink(job);
	abend("spool: %s", strerror(errno));
    }

    fprintf(output, "#! /bin/sh\n");
    
    /*
     * write a koeneg-at compatable header
     */
    fprintf(output, "# atrun uid=%d gid=%d\n", getuid(), getgid());
    fprintf(output, "# mail      %s %d\n", user->pw_name, notify);
    
    /* 
     * write out the environment
     */
    fprintf(output, "umask %o\n", i=umask(0777)); umask(i);
    
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
		    if ( ! (isalnum(*r) || *r == '/' || *r == ':') )
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

    fprintf(output, "\ncd %s || exit 1\n\n", pwd);

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
    time_t now, jobtime;
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
		if ( redirect )
		    abend("too many -f options");
		if ( freopen(optarg, "r", stdin) == 0 )
		    abend("%s", strerror(errno));
	default:
	    usage();
	}

    argc -= optind;
    argv += optind;

    if ( argc < 1 )
	usage();
       
    jobtime = maketime(argc, argv, abend);

    if ( debug & (0x04|0x08) )
	time(&now);
    if ( debug & 0x04 )
	printf("now: %s", ctime(&now));
    if ( debug & 0x01 )
	printf("job: %s", ctime(&jobtime));
    if ( debug & 0x08 )
	printf("%ld\n", jobtime-now);    
    if ( !(debug & 0x02) )
	savejob(jobtime);
    exit(0);
}
