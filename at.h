#ifndef _AT_H
#define _AT_H 1

typedef struct atjobtime {
    int special;
    int minute, hour, day, month, year;
    int offset;
    int units;		/* MINUTE HOUR DAY WEEK MONTH YEAR */
    int plural;		/* <interval>(s) */
    int pm;		/* 0 : unset; 1: am; 2: pm */
} atjobtime;

#define YYSTYPE int

#define ATDIR	"/var/spool/cron/atjobs"

extern int yyparse(), yylex();
extern int yy_prepare(atjobtime *,int,char **);
extern void abend(char *, ...);

#endif/*_AT_H*/
