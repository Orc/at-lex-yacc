/* Copyright 2007 by David Loren Parsons (orc@pell.chi.il.us)
 * See the COPYRIGHT file included in this distribution for
 * terms of use.
 */
/*
 * atq: show the contents of the atjob queue
 */
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdlib.h>
#include <unistd.h>
#include <dirent.h>
#include <pwd.h>
#include "at.h"


#ifndef HAVE_BASENAME
#   include <string.h>
#elif HAVE_LIBGEN_H
#   include <libgen.h>
#endif


#ifndef HAVE_BASENAME
static char*
basename(char *p)
{
    char *ret = strrchr(p, '/');

    return ret ? (1+ret) : p;
}
#endif

int
main(int argc, char **argv)
{
    DIR *p;
    struct dirent *de;
    time_t jobtime;
    int seq;
    int opt, totals = 0, count = 0;
    int sort_by_creation_date = 0;
    uid_t me = getuid();
    char *pgm;
    char q;
    int iamroot = !me;
    int needheader = 1;
    struct stat jobstat;
    struct passwd *pwd;

    pgm = basename(argv[0]);

    while ( (opt=getopt(argc, argv, iamroot ? "cnu:" : "cn")) != EOF ) {
	switch (opt) {
	case 'n':   totals = 1;
		    break;
	case 'c':   sort_by_creation_date = 1;
		    break;
	case 'u':   if ( (pwd=getpwnam(optarg)) == 0 ) {
			fprintf(stderr, "%s: no user %s\n", pgm, optarg);
			exit(1);
		    }
		    me = pwd->pw_uid;
		    iamroot = 0;
		    break;
	default:    fprintf(stderr, "usage: %s [-cn]%s\n",
				    pgm, (getuid() == 0) ? " [-u user]" : "");
		    exit(1);
	}
    }

    if ( chdir(ATDIR) != 0 ) {
	perror(ATDIR);
	exit(1);
    }

    if ( p = opendir(".") ) {
	while ( de = readdir(p) )
	    if ( (sscanf(de->d_name, "%c%5x%8lx", &q, &seq, &jobtime) == 3)
					&& (stat(de->d_name, &jobstat) == 0)
				      && (iamroot || (me == jobstat.st_uid))
				         && (pwd = getpwuid(jobstat.st_uid)) ) {
		if (totals) count++;
		else {
		    if (needheader) {
			putchar(' ');
			if (iamroot)
			    printf("%-8s ", "user");
			printf("%-13s %10s%s\n", "job", "", "  time");
			needheader=0;
		    }
		    jobtime *= 60;
		    if (iamroot)
			printf("%-8s ", pwd->pw_name);
		    printf("%-13s %10s%s", de->d_name, "", ctime(&jobtime));
		}
	    }
	closedir(p);
    }
    if (totals) printf("%d\n", count);
    exit(0);
}
