/* Copyright 2025 by Jessica Loren Parsons (orc@pell.portland.or.us)
 * See the COPYRIGHT file included in this distribution for
 * terms of use.
 */

#include "config.h"
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <syslog.h>


int
isowner(struct stat *st)
{
    uid_t me = getuid();
    
    if (me == 0) return 1;
    else return (me == st->st_uid);
}

int
main(argc,argv)
int argc;
char **argv;
{
    struct stat st;
    int oops = 0;
    int i;

    if ( chdir(ATDIR) != 0 ) {
	perror(ATDIR);
	exit(1);
    }
    for (i=1; i < argc; i++)
	if ( strchr(argv[i], '/') ) {
	    fprintf(stderr, "%s: bad job-id\n", argv[i]);
	    exit(1);
	}

    openlog("atrm", LOG_PID, LOG_CRON);

    for (i=1; i < argc; i++) {
	if ( stat(argv[i], &st) != 0 ) {
	    perror(argv[i]);
	    oops++;
	}
	else if ( isowner(&st) && (st.st_mode & S_IFREG) ) {
	    if ( unlink(argv[i]) != 0 ) {
		perror(argv[i]);
		oops++;
	    }
	    syslog(LOG_INFO, "User %d removed job %s", getuid(), argv[i]);
	}
	else {
	    errno = EPERM;
	    perror(argv[i]);
	}
    }
    exit (oops ? 2 : 0);
}
