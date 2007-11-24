%{
#include <stdio.h>
#include <string.h>
#include <time.h>
#include "y.tab.h"
#include "at.h"

static char      *yy_source = 0;
static int        yy_size = 0;
static int        yy_index = 0;

static void (*yy_abend)(char*,...) = 0;

static void
yyerror(const char *why)
{
    if ( yy_abend )
	(*yy_abend)("%s", why);
    fprintf(stderr, why);
}

static void
yyunit(atjobtime *at, int which, int plural)
{

    at->units = which;
    at->plural = plural;
}

static int
ok(int min, int value, int max)
{
    return (value >= min) && (value <= max);
}


static int
yyset(struct atjobtime *at, int value, int unit)
{
    int good = 1;
    
    switch (unit) {
    case MINUTE:if (at->hour == 12 || at->hour == 24)
		    good = (value <= 30) ;
		else
		    good = ok(0,value,59);
		break;
    case HOUR:  good = ok(0,value, (at->pm ? 12 : 24) ); break;
    case DAY:   good = ok(1,value,31); break;
    case MONTH: good = ok(1,value,12); break;
    }

    if ( !good )
	yyerror("time/date error");

    return value;
}


static void
yysetdate(struct atjobtime *at, int day, int month, int year)
{
    at->day = yyset(at, day, DAY);
    at->month = yyset(at, month, MONTH)-1;
    if ( year ) {
	at->year = year;
    }
}


int
yywrap()
{
    return 1;
}


static atjobtime *yy_at;


int
yy_input_me(char *bfr, int wanted)
{
    if ( yy_index >= yy_size-1 )
	return 0;
	
    if ( wanted > (yy_size - yy_index) )
	wanted = yy_size - yy_index;

    memcpy(bfr, yy_source, wanted);

    yy_index += wanted;

    return wanted;
}


int
yy_prepare(atjobtime *at, int argc, char **argv,void (*abend)(char*,...))
{
    int i;
    time_t tt;
    struct tm* tm;

    time(&tt);
    tm = localtime(&tt);

    bzero(at, sizeof *at);
    at->hour = at->minute = -1;
    at->abend = yy_abend = abend;
    
    yy_at = at;
    
    for (yy_size=0,i=0; i < argc; i++) {
	if (i)
	    yy_size++;
	yy_size += strlen(argv[i]);
    }

    if ( yy_size < 1 )
	return 0;

    if ( (yy_source = malloc(yy_size)) == 0 )
	return 0;

    yy_index = 0;
    yy_source[0] = 0;

    for (i=0; i < argc; i++) {
	if (i)
	    strcat(yy_source, " ");
	strcat(yy_source, argv[i]);
    }

    return yy_size;
}

%}

%token NUMBER DOT COLON AM PM NOON MIDNIGHT TEATIME TODAY TONIGHT 
%token TOMORROW DAY WEEK MONTH YEAR FROM NOW NEXT MINUTE HOUR DASH
%token SLASH PLUS MONTHNAME EXACTLY SOONEST DAYNAME COMMA YESTERDAY
%token ERROR

%%

when:	NOW PLUS offset
    |	time
    |	time date
    |	date
    ;

date:	PLUS offset
    |   fromnow
    |	NEXT nxunit
    |	datespec
    |	specialdate
    ;

fromnow:	EXACTLY offset FROM fromtime
	|	offset FROM fromtime
	;

offset:		NUMBER unit
		{ yy_at->offset = $1; }
	|	unit
		{ yy_at->offset = 1; }
	;
	
nxunit:		dayname
	|	dayunit
		{ yy_at->offset = 1; }
	;
	
unit:	MINUTE
	{ yyunit(yy_at, MINUTE, $1); }
    |	HOUR
	{ yyunit(yy_at, HOUR, $1); }
    |	DAY
	{ yyunit(yy_at, DAY, $1); }
    |	dayunit
    ;
    
dayunit:	WEEK
		{ yyunit(yy_at, WEEK, $1); }
	|	MONTH
		{ yyunit(yy_at, MONTH, $1); }
	|	YEAR
		{ yyunit(yy_at, YEAR, $1); }
	;

dayname:	DAYNAME
		{ yy_at->special = DAYNAME; yy_at->value = $1; }
	;

fromtime:	specialdate
		{ if (yy_at->special == TONIGHT) yy_at->special = TODAY; }
	|	NOW
	|	YESTERDAY
		{ yy_at->special = YESTERDAY; }
	;

specialdate:	TODAY
		{ yy_at->special = TODAY; }
	|	TONIGHT
		{ yy_at->special = TONIGHT; }
	|	TOMORROW
		{ yy_at->special = TOMORROW; }
	|	dayname
	;

time:	NOON
	{ yy_at->hour = 12; yy_at->minute = 0; }
    |	TEATIME
	{ yy_at->hour = 16; yy_at->minute = 0; }
    |	MIDNIGHT
	{ yy_at->hour = 24; yy_at->minute = 0; }
    |	NUMBER ampm
	{ yy_at->hour = $1; yy_at->minute = 0; }
    |	NUMBER COLON NUMBER optampm
	{ yy_at->hour = $1; yy_at->minute = $3; }
    ;

optampm:	/* empty */
	|	ampm
	;

ampm:	AM
	{ yy_at->pm = 1; }
    |	PM
	{ yy_at->pm = 2; }
    ;

datespec:	slashed_date
	|	dotted_date
	|	named_date
	;

slashed_date:	NUMBER SLASH NUMBER SLASH NUMBER
		{ yysetdate(yy_at, $3, $1, $5); }
	    ;

dotted_date:	NUMBER DOT NUMBER
		{ yysetdate(yy_at, $1, $3, 0); }
	    |	NUMBER DOT NUMBER DOT NUMBER
		{ yysetdate(yy_at, $1, $3, $5); }
	    ;

named_date:	NUMBER DASH MONTHNAME
		{ yysetdate(yy_at, $1, $3, 0); }
	    |	NUMBER DASH MONTHNAME DASH NUMBER
		{ yysetdate(yy_at, $1, $3, $5); }
	    |	MONTHNAME NUMBER
		{ yysetdate(yy_at, $2, $1, 0); }
	    |	MONTHNAME NUMBER NUMBER
		{ yysetdate(yy_at, $2, $1, $3); }
	    |	MONTHNAME NUMBER COMMA NUMBER
		{ yysetdate(yy_at, $2, $1, $4); }
	    |	NUMBER MONTHNAME
		{ yysetdate(yy_at, $1, $2, 0); }
	    |	NUMBER MONTHNAME NUMBER
		{ yysetdate(yy_at, $1, $2, $3); }
	    ;

