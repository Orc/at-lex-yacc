#ifndef _AT_H
#define _AT_H 1

#include <time.h>

typedef struct atjobtime {
    int minute, hour, day, month, year;
    int units;		/* MINUTE HOUR DAY WEEK MONTH YEAR */
    int offset;
    int special;	/* MONDAY TUESDAY ... SUNDAY TODAY TONIGHT TOMORROW */
    int value;
    int plural;		/* <interval>(s) */
    int pm;		/* 0 : unset; 1: am; 2: pm */
} atjobtime;

#define YYSTYPE int

#define ATDIR	"/var/spool/cron/atjobs"

extern time_t maketime(int,char**);
extern int yyparse(), yylex();
extern int yy_prepare(atjobtime *,int,char **);
extern void abend(char *, ...);

#endif/*_AT_H*/
