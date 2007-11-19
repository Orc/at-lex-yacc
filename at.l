%{
#include <stdio.h>
#include <string.h>
#include "y.tab.h"
#include "at.h"

extern YYSTYPE yylval;

#if DEBUG
#define SAY	fprintf(stderr, "%s ", yytext);
#else
#define SAY
#endif

extern int yy_input_me(char *buf, int size);
extern int plural(char *s);

#define YY_INPUT(b,r,max)	(r = yy_input_me(b,max))
%}

%%

[0-9]+		{ SAY yylval = atoi(yytext); return NUMBER; }
\.		{ SAY return DOT; }
\:		{ SAY return COLON; }
AM		{ SAY return AM; }
PM		{ SAY return PM; }
NOON		{ SAY return NOON; }
MIDNIGHT	{ SAY return MIDNIGHT; }
TEATIME		{ SAY return TEATIME; }
TODAY		{ SAY return TODAY; }
TONIGHT		{ SAY return TONIGHT; }
TOMORROW	{ SAY return TOMORROW; }
MINUTES?	{ SAY yylval = plural(yytext); return MINUTE; }
HOURS?		{ SAY yylval = plural(yytext); return HOUR; }
DAYS?		{ SAY yylval = plural(yytext); return DAY; }
WEEKS?		{ SAY yylval = plural(yytext); return WEEK; }
MONTHS?		{ SAY yylval = plural(yytext); return MONTH; }
YEARS?		{ SAY yylval = plural(yytext); return YEAR; }
FROM		{ SAY return FROM; }
NOW		{ SAY return NOW; }
NEXT		{ SAY return NEXT; }
EXACTLY		{ SAY return EXACTLY; }
JAN(UARY)?	{ SAY yylval= 1; return MONTHNAME; }
FEB(RUARY)?	{ SAY yylval= 2; return MONTHNAME; }
MAR(CH)?	{ SAY yylval= 3; return MONTHNAME; }
APR(IL)?	{ SAY yylval= 4; return MONTHNAME; }
MAY		{ SAY yylval= 5; return MONTHNAME; }
JUNE?		{ SAY yylval= 6; return MONTHNAME; }
JULY?		{ SAY yylval= 7; return MONTHNAME; }
AUG(UST)?	{ SAY yylval= 8; return MONTHNAME; }
SEP(TEMBER)?	{ SAY yylval= 9; return MONTHNAME; }
OCT(OBER)?	{ SAY yylval=10; return MONTHNAME; }
NOV(EMBER)?	{ SAY yylval=11; return MONTHNAME; }
DEC(EMBER)?	{ SAY yylval=12; return MONTHNAME; }
\-		{ SAY return DASH; }
\/		{ SAY return SLASH; }
\+		{ SAY return PLUS; }
[ \t\r]+	;
[a-z][a-z0-9]*	{ SAY return ERROR; }
.		{ SAY return ERROR; }

