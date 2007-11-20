%{
#include <stdio.h>
#include <string.h>
#include <time.h>
#include "y.tab.h"
#include "at.h"

static char      *yy_source = 0;
static int        yy_size = 0;
static int        yy_index = 0;

void
yyerror(const char *why)
{
    fprintf(stderr, "%s\n", why);
    exit(1);
}


int
plural(char *s)
{
    int len = strlen(s);

    return (len > 0) && (s[len-1] == 's');
}

int
yyunits(struct atjobtime *at, int offset)
{
    if ( at->plural ) {
	if ( offset == 1)
	    yyerror("quantity error");
    }
    else {
	if ( offset != 1)
	    yyerror("quantity error");
    }
    at->offset = offset;
}

static int
ok(int min, int value, int max)
{
    return (value >= min) && (value <= max);
}

void
yysetdate(struct atjobtime *at, int day, int month, int year)
{
    at->day = yyset(at, day, DAY);
    at->month = yyset(at, month, MONTH)-1;
    at->year = year;
}


int
yyset(struct atjobtime *at, int value, int unit)
{
    int good = 1;
    
    switch (unit) {
    case MINUTE:if (at->hour == 12 || at->hour == 24)
		    good = (value == 0) ;
		else
		    good = ok(0,value,59);
		break;
    case HOUR:  good = ok(0,value, (at->pm >= 0) ? 12 : 24 ); break;
    case DAY:   good = ok(1,value,31); break;
    case MONTH: good = ok(1,value,12); break;
    }

    if ( !good )
	yyerror("time/date error");

    return value;
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
yy_prepare(struct atjobtime *at, int argc, char **argv)
{
    int i;
    
    bzero(at, sizeof *at);
    at->mode = DATE;
    at->year = at->month = at->day = at->pm = -1;
    
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


void
dump(atjobtime *a)
{
    if (a->mode == DATE) {
	fprintf(stderr, "<%d:%02d", a->hour, a->minute);
	if (a->pm >= 0)
	    fprintf(stderr," %s", a->pm ? "pm" : "am");
	switch (a->special) {
	case TODAY:
	    fprintf(stderr, " today");
	    break;
	case TONIGHT:
	    fprintf(stderr, " tonight");
	    break;
	case TOMORROW:
	    fprintf(stderr, " tomorrow");
	    break;
	case SOONEST:
	    fprintf(stderr, " soonest");
	    break;
	default:
	    fprintf(stderr, " %d.%d", a->day, a->month + 1);
	break;
	}
	if (a->year > 0)
	    fprintf(stderr, ".%d", a->year);
	fputc('>',stderr);
    }
    else {
	fputc('<',stderr);
	if (a->mode == EXACT_OFFSET)
	    fprintf(stderr,"%d:%02d %s, ",
		    a->hour,a->minute,
		    a->pm ? "pm":"am");
	fprintf(stderr, "offset=%d,units=%d%s>",
		a->offset,a->units,
		(a->mode==OFFSET)?"":",EXACT");
    }
    fputc('\n', stderr);
}

%}

%token NUMBER DOT COLON AM PM NOON MIDNIGHT TEATIME TODAY TONIGHT 
%token TOMORROW DAY WEEK MONTH YEAR FROM NOW NEXT MINUTE HOUR DASH
%token SLASH PLUS MONTHNAME EXACTLY SOONEST DAYNAME
%token ERROR

%%

when:	EXACTLY date_offset FROM NOW
	{ yy_at->mode = EXACT_OFFSET; }
    |	delay_time
    |	delay_days
    |	time date
	{ yy_at->mode = DATE; }
    |   time delay_days
    |	time next_interval
	{ yy_at->mode = DATE; }
    ;

next_interval:	NEXT next_offset
		{ yy_at->mode = DATE; }
	;

next_offset:	WEEK
		{ yy_at->special = WEEK; }
	|	MONTH
		{ yy_at->special = MONTH; }
	|	YEAR
		{ yy_at->special = YEAR; }
	|	DAYNAME
		{ yy_at->special = DAYNAME; yy_at->offset = yylval; }
	;

delay_time:	PLUS time_offset
		{ yy_at->mode = EXACT_OFFSET; }
	|	time_offset FROM NOW
		{ yy_at->mode = EXACT_OFFSET; }
	|	next_interval
		{ yy_at->mode = DATE; }
	;

delay_days:	PLUS date_offset
		{ yy_at->mode = OFFSET; }
	|	date_offset FROM NOW
		{ yy_at->mode = OFFSET; }
	;
	

date_offset:	NUMBER day_interval
		{ yyunits(yy_at, $1); }
	    ;

time_offset:	NUMBER interval
		{ yyunits(yy_at, $1); }
		;

interval:	MINUTE
		{ yy_at->units = MINUTE; yy_at->plural = $1; }
	|	HOUR
		{ yy_at->units = HOUR; yy_at->plural = $1; }
	;

day_interval:	DAY
		{ yy_at->units = DAY; yy_at->plural = $1; }
	    |	WEEK
		{ yy_at->units = WEEK; yy_at->plural = $1; }
	    |	MONTH
		{ yy_at->units = MONTH; yy_at->plural = $1; }
	    |	YEAR
		{ yy_at->units = YEAR; yy_at->plural = $1; }
	    ;

time:	NUMBER ampm
	{   yy_at->minute = 0;
	    yy_at->hour = yyset(yy_at, $1, HOUR); }
    |	NUMBER COLON NUMBER optional_ampm
	{   yy_at->minute = yyset(yy_at, $3, MINUTE);
	    yy_at->hour = yyset(yy_at, $1, HOUR); }
    |	NOON
	{ yy_at->hour = 12; yy_at->minute = 0; }
    |	MIDNIGHT
	{ yy_at->hour = 23; yy_at->minute = 60; }
    |	TEATIME
	{ yy_at->hour = 16; yy_at->minute = 0; }
    ;
    
ampm:	AM
	{ yy_at->pm = 0; }
    |	PM
	{ yy_at->pm = 1; }
    ;

optional_ampm:	/* doesn't need to be here */
	    |	ampm
	    ;

date:	/* doesn't need to be here */
	{ yy_at->special = SOONEST; }
    |	TODAY
	{ yy_at->special = TODAY; }
    |	TONIGHT
	{ yy_at->special = TONIGHT; }
    |	TOMORROW
	{ yy_at->special = TOMORROW; }
    |	slashed_date
    |	dotted_date
    |	dashed_date
    |   month_date
    ;

slashed_date:	NUMBER SLASH NUMBER SLASH NUMBER
		{ yysetdate(yy_at, $3, $1, $5); }
	    ;

dotted_date:	NUMBER DOT NUMBER DOT NUMBER
		{ yysetdate(yy_at, $1, $3, $5); }
	    ;

dashed_date:	date_with_dashes
	    |	date_without_dashes
	    ;

month_date:	MONTHNAME NUMBER
		{ yysetdate(yy_at, $2, $1, -1); }
	    |	MONTHNAME NUMBER NUMBER
		{ yysetdate(yy_at, $2, $1, $3); }
	    ;

date_with_dashes:	NUMBER DASH MONTHNAME
			{ yysetdate(yy_at, $1, $3, -1); }
		|	NUMBER DASH MONTHNAME DASH NUMBER
			{ yysetdate(yy_at, $1, $3, $5); }
		;

date_without_dashes:	NUMBER MONTHNAME
			{ yysetdate(yy_at, $1, $2, -1); }
		    |	NUMBER MONTHNAME NUMBER
			{ yysetdate(yy_at, $1, $2, $3); }
		    ;

