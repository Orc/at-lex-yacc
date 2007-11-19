%{
#include <stdio.h>
#include <string.h>

void
yyerror(const char *why)
{
    fprintf(stderr, "<< %s", why);
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

    if (yy_size > 0) {
	yyparse();
	fputc('\n', stderr);
    }
}
%}

%token NUMBER DOT COLON AM PM NOON MIDNIGHT TEATIME TODAY TONIGHT 
%token TOMORROW DAY WEEK MONTH YEAR FROM NOW  NEXT MINUTE HOUR DASH
%token SLASH PLUS MONTHNAME EXACTLY ERROR

%%

jobtime:	job_delay_time
	|	time date
	;

job_delay_time:	EXACTLY NUMBER day_interval FROM NOW
	|	delay_time
	;
	
delay_time:	PLUS time_offset
	|	time_offset FROM NOW
	|	NEXT day_interval
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

date:	/* doesn't need to be here */
    |	TODAY
    |	TONIGHT
    |	TOMORROW
    |	delay_time
    |	slashed_date
    |	dotted_date
    |	dashed_date
    |   month_date
    ;

slashed_date:	NUMBER SLASH NUMBER SLASH NUMBER
	    ;

dotted_date:	NUMBER DOT NUMBER DOT NUMBER
	    ;

dashed_date:	date_with_dashes
	    |	date_without_dashes
	    ;

month_date:	MONTHNAME NUMBER
	    |	MONTHNAME NUMBER NUMBER
	    ;

date_with_dashes:	NUMBER DASH MONTHNAME
		|	NUMBER DASH MONTHNAME DASH NUMBER
		;

date_without_dashes:	NUMBER MONTHNAME
		    |	NUMBER MONTHNAME NUMBER
		    ;
