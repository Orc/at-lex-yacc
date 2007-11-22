#ifndef _AT_H
#define _AT_H 1

typedef struct atjobtime {
    enum { OFFSET, EXACT_OFFSET, DATE } mode;
    int special;	/* TONIGHT, TOMORROW, TODAY */
    int minute, hour, day, month, year;
    int offset;
    int units;		/* MINUTE HOUR DAY WEEK MONTH YEAR */
    int plural;		/* <interval>(s) */
    int pm;		/* am or pm */
} atjobtime;

#define YYSTYPE int

#define ATDIR	"/var/spool/cron/atjobs"

extern void abend(char *, ...);
extern int yyparse();
extern int yy_prepare(atjobtime *,int,char **);
extern int yylex();

#endif/*_AT_H*/
