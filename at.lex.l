%{
/* Copyright 2007 by David Loren Parsons (orc@pell.chi.il.us)
 * See the COPYRIGHT file included in this distribution for
 * terms of use.
 */
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
extern int yy_plural(char *s);

#define YY_INPUT(b,r,max)	(r = yy_input_me(b,max))
%}

%option nounput

%%

[0-9]+		{ SAY yylval = atoi(yytext); return NUMBER; }
\.		{ SAY return DOT; }
\:		{ SAY return COLON; }
AM		{ SAY return AM; }
PM		{ SAY return PM; }
ONE		{ SAY yylval = 1; return NUMBER; }
TWO		{ SAY yylval = 2; return NUMBER; }
THREE		{ SAY yylval = 3; return NUMBER; }
FOUR		{ SAY yylval = 4; return NUMBER; }
FIVE		{ SAY yylval = 5; return NUMBER; }
SIX		{ SAY yylval = 6; return NUMBER; }
SEVEN		{ SAY yylval = 7; return NUMBER; }
EIGHT		{ SAY yylval = 8; return NUMBER; }
NINE		{ SAY yylval = 9; return NUMBER; }
TEN		{ SAY yylval = 10; return NUMBER; }
NOON		{ SAY return NOON; }
MIDNIGHT	{ SAY return MIDNIGHT; }
TEATIME		{ SAY return TEATIME; }
TODAY		{ SAY return TODAY; }
TONIGHT		{ SAY return TONIGHT; }
TOMORROW	{ SAY return TOMORROW; }
YESTERDAY	{ SAY return YESTERDAY; }
LAST		{ SAY return LAST; }
MINUTES?	{ SAY yylval = yy_plural(yytext); return MINUTE; }
HOURS?		{ SAY yylval = yy_plural(yytext); return HOUR; }
DAYS?		{ SAY yylval = yy_plural(yytext); return DAY; }
WEEKS?		{ SAY yylval = yy_plural(yytext); return WEEK; }
MONTHS?		{ SAY yylval = yy_plural(yytext); return MONTH; }
YEARS?		{ SAY yylval = yy_plural(yytext); return YEAR; }
FROM		{ SAY return FROM; }
NOW		{ SAY return NOW; }
NEXT		{ SAY return NEXT; }
EXACTLY		{ SAY return EXACTLY; }
SUN(DAY)?	{ SAY yylval= 0; return DAYNAME; }
MON(DAY)?	{ SAY yylval= 1; return DAYNAME; }
TUE(SDAY)?	{ SAY yylval= 2; return DAYNAME; }
WED(NESDAY)?	{ SAY yylval= 3; return DAYNAME; }
THU(RSDAY)?	{ SAY yylval= 4; return DAYNAME; }
FRI(DAY)?	{ SAY yylval= 5; return DAYNAME; }
SAT(URDAY)?	{ SAY yylval= 6; return DAYNAME; }
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
\,		{ SAY return COMMA; }
[ \t\r]+	;
[a-z][a-z0-9]*	{ SAY return ERROR; }
