%{
#include <stdio.h>
#include "y.tab.h"

#if DEBUG
#define NEWLINE	putchar('\n');
#define SAY	ECHO; putchar(' ');
#else
#define SAY
#define NEWLINE
#endif
%}

%%

[0-9]+		{ SAY return NUMBER; }
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
MINUTES?	{ SAY return MINUTE; }
HOURS?		{ SAY return HOUR; }
DAYS?		{ SAY return DAY; }
WEEKS?		{ SAY return WEEK; }
MONTHS?		{ SAY return MONTH; }
YEARS?		{ SAY return YEAR; }
FROM		{ SAY return FROM; }
NOW		{ SAY return NOW; }
NEXT		{ SAY return NEXT; }
JAN(UARY)?	{ SAY return MONTHNAME; }
FEB(RUARY)?	{ SAY return MONTHNAME; }
MAR(CH)?	{ SAY return MONTHNAME; }
APR(IL)?	{ SAY return MONTHNAME; }
MAY		{ SAY return MONTHNAME; }
JUNE?		{ SAY return MONTHNAME; }
JULY?		{ SAY return MONTHNAME; }
AUG(UST)?	{ SAY return MONTHNAME; }
SEP(TEMBER)?	{ SAY return MONTHNAME; }
OCT(OBER)?	{ SAY return MONTHNAME; }
NOV(EMBER)?	{ SAY return MONTHNAME; }
DEC(EMBER)?	{ SAY return MONTHNAME; }
\-		{ SAY return DASH; }
\/		{ SAY return SLASH; }
\+		{ SAY return PLUS; }
[\n]+		{ NEWLINE return EOL; }
[ \t\r]+	;
