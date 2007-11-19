%{
#include <stdio.h>
#include <string.h>
#include <time.h>
#include "y.tab.h"
#include "at.h"

struct atjobtime at;


void
yyerror(const char *why)
{
    fprintf(stderr, "<< %s\n", why);
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
    at->month = yyset(at, month, MONTH);
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

static char *yy_source;
static int   yy_size;
static int   yy_index;

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


main(argc, argv)
char **argv;
{
    int i;

    for (yy_size=0,i=1; i < argc; i++) {
	if (i > 1)
	    yy_size++;
	yy_size += strlen(argv[i]);
    }

    yy_source = alloca(yy_size);
    yy_index = 0;
    yy_source[0] = 0;

    for (i=1; i < argc; i++) {
	if (i > 1)
	    strcat(yy_source, " ");
	strcat(yy_source, argv[i]);
    }

    bzero(&at, sizeof at);
    at.mode = DATE;
    at.pm = -1;
    if (yy_size > 0) {
	yyparse();
	fputc('\n', stderr);
    }
}
%}

%token NUMBER DOT COLON AM PM NOON MIDNIGHT TEATIME TODAY TONIGHT 
%token TOMORROW DAY WEEK MONTH YEAR FROM NOW  NEXT MINUTE HOUR DASH
%token SLASH PLUS MONTHNAME EXACTLY ERROR SOONEST

%%

job:	when
	{	if (at.mode == DATE) {
		    fprintf(stderr, "<%d:%02d", at.hour, at.minute);
		    if (at.pm >= 0)
			fprintf(stderr," %s", at.pm ? "pm" : "am");
		    switch (at.special) {
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
			    break;
		    default:
			    fprintf(stderr, " %d.%d", at.day,at.month);
			    break;
		    }
		    if (at.year)
			fprintf(stderr, ".%d", at.year);
		    fputc('>',stderr);
		}
		else {
		    fputc('<',stderr);
		    if (at.mode == EXACT_OFFSET)
			fprintf(stderr,"%d:%02d %s, ",
				    at.hour,at.minute, at.pm ? "pm":"am");
		    fprintf(stderr, "offset=%d,units=%d%s>",
			    at.offset,at.units,
			    (at.mode==OFFSET)?"":",EXACT");
		}
		fflush(stderr);
	}
    ;

when:	EXACTLY date_offset
	{   struct tm *t; time_t ttt;
	    time(&ttt);
	    t = gmtime(&ttt);
	    at.hour = t->tm_hour;
	    at.minute = t->tm_min;
	    at.mode = EXACT_OFFSET; }
    |	delay_time
	{ at.mode = OFFSET; }
    |	time date
    ;

next_interval:	NEXT day_interval
		{ yyunits(&at, 1); }
	;

delay_time:	PLUS time_offset
	|	time_offset FROM NOW
	|	next_interval
	;

delay_days:	PLUS date_offset
	|	date_offset FROM NOW
	|	next_interval
	;
	

date_offset:	NUMBER day_interval FROM NOW
		{ yyunits(&at, $1); }
	    ;

time_offset:	NUMBER interval
		{ yyunits(&at, $1); }
		;

interval:	MINUTE
		{ at.units = MINUTE; at.plural = $1; }
	|	HOUR
		{ at.units = HOUR; at.plural = $1; }
	|	day_interval
	;

day_interval:	DAY
		{ at.units = DAY; at.plural = $1; }
	    |	WEEK
		{ at.units = WEEK; at.plural = $1; }
	    |	MONTH
		{ at.units = MONTH; at.plural = $1; }
	    |	YEAR
		{ at.units = YEAR; at.plural = $1; }
	    ;

time:	NUMBER ampm
	{   at.minute = 0;
	    at.hour = yyset(&at, $1, HOUR); }
    |	NUMBER COLON NUMBER optional_ampm
	{   at.minute = yyset(&at, $3, MINUTE);
	    at.hour = yyset(&at, $1, HOUR); }
    |	NOON
	{ at.hour = 12; at.minute = 0; }
    |	MIDNIGHT
	{ at.hour = 0; at.minute = 0; }
    |	TEATIME
	{ at.hour = 4; at.minute = 0; at.pm = 1; }
    ;
    
ampm:	AM
	{ at.pm = 0; }
    |	PM
	{ at.pm = 1; }
    ;

optional_ampm:	/* doesn't need to be here */
		{ at.pm = 0; }
	    |	ampm
	    ;

date:	/* doesn't need to be here */
	{ at.special = SOONEST; }
    |	TODAY
	{ at.special = TODAY; }
    |	TONIGHT
	{ at.special = TONIGHT; }
    |	TOMORROW
	{ at.special = TOMORROW; }
    |   delay_time
	{ at.mode = EXACT_OFFSET; }
    |	slashed_date
    |	dotted_date
    |	dashed_date
    |   month_date
    ;

slashed_date:	NUMBER SLASH NUMBER SLASH NUMBER
		{ yysetdate(&at, $3, $1, $5); }
	    ;

dotted_date:	NUMBER DOT NUMBER DOT NUMBER
		{ yysetdate(&at, $1, $3, $5); }
	    ;

dashed_date:	date_with_dashes
	    |	date_without_dashes
	    ;

month_date:	MONTHNAME NUMBER
		{ yysetdate(&at, $2, $1, -1); }
	    |	MONTHNAME NUMBER NUMBER
		{ yysetdate(&at, $2, $1, $3); }
	    ;

date_with_dashes:	NUMBER DASH MONTHNAME
			{ yysetdate(&at, $1, $3, -1); }
		|	NUMBER DASH MONTHNAME DASH NUMBER
			{ yysetdate(&at, $1, $3, $5); }
		;

date_without_dashes:	NUMBER MONTHNAME
			{ yysetdate(&at, $1, $2, -1); }
		    |	NUMBER MONTHNAME NUMBER
			{ yysetdate(&at, $1, $2, $3); }
		    ;
