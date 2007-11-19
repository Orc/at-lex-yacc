%{
#include <stdio.h>
#include <string.h>

void
yyerror(const char *why)
{
    fprintf(stderr, "error: %s\n", why);
}

int
yywrap()
{
    return 1;
}

main()
{
	yyparse();
}
%}

%token NUMBER DOT COLON AM PM NOON MIDNIGHT TEATIME TODAY TONIGHT 
%token TOMORROW DAY WEEK MONTH YEAR FROM NOW  NEXT MINUTE HOUR DASH
%token SLASH PLUS MONTHNAME EOL ERROR

%%

debug:		/* for debugging- empty is ok */
	|	debug jobtime EOL
	;

jobtime:	PLUS time_offset
	|	time_offset FROM NOW
	|	NEXT day_interval
	|	time optional_date
	;

time_offset: NUMBER interval ;

interval:	MINUTE
	|	HOUR
	|	day_interval
	;

day_interval:	DAY
	    |	WEEK
	    |	MONTH
	    |	YEAR
	    ;

time:	NUMBER ampm
    |	NUMBER COLON NUMBER optional_ampm
    |	NOON
    |	MIDNIGHT
    |	TEATIME
    ;
    
ampm:	AM
    |	PM
    ;

optional_ampm:	/* doesn't need to be here */
	    |	ampm
	    ;

optional_date:	/* doesn't need to be here */
	    |	TODAY
	    |	TONIGHT
	    |	TOMORROW
	    |	NUMBER day_interval FROM NOW
	    |	NEXT day_interval
	    |	slashed_date
	    |	dotted_date
	    |	dashed_date
	    ;

slashed_date:	NUMBER SLASH NUMBER SLASH NUMBER
	    ;

dotted_date:	NUMBER DOT NUMBER DOT NUMBER
	    ;

dashed_date:	date_with_dashes
	    |	date_without_dashes
	    ;

date_with_dashes:	NUMBER DASH MONTHNAME
		|	NUMBER DASH MONTHNAME DASH NUMBER
		;

date_without_dashes:	NUMBER MONTHNAME
		    |	NUMBER MONTHNAME NUMBER
		    ;
