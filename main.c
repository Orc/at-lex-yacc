#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#include "at.h"
#include "y.tab.h"


static void
offset(atjobtime *at, struct tm *tm)
{
    switch (at->units) {
    case MINUTE:	tm->tm_min += at->offset;
			break;
    case HOUR:		tm->tm_hour += at->offset;
			break;
    case DAY:		tm->tm_mday += at->offset;
			break;
    case WEEK:		tm->tm_mday += 7 * at->offset;
			break;
    case MONTH:		tm->tm_mon += at->offset;
			break;
    case YEAR:		tm->tm_year += at->offset;
			break;
    }
}


static time_t
maketime(atjobtime *at)
{
    time_t now, madetime;
    struct tm *t;
    int at_tod, tm_tod;
    int at_hour = at->hour;

    if (at->pm > 0) at->hour += 12;
    
    time(&now);
    t = localtime(&now);

    t->tm_sec = 0;

    switch (at->mode) {
    case DATE:
	    if ( at->year != -1 ) t->tm_year = at->year - 1900;

	    at_tod = (at->hour * 60) + at->minute;
	    tm_tod = (t->tm_hour * 60) + t->tm_min;
	    
	    t->tm_hour = at->hour;
	    t->tm_min = at->minute;
	    
	    switch (at->special) {
	    case TODAY:	break;
	    case TOMORROW:
			if ( at->month >= 0 ) t->tm_mon = at->month;
			if ( at->day > 0 ) t->tm_mday = at->day;
			t->tm_mday++;
			break;
	    case TONIGHT:
			if ( at->month >= 0 ) t->tm_mon = at->month;
			if ( at->day > 0) t->tm_mday = at->day;
			if ( (at->pm <= 0) && (at->hour < 3) )
			    t->tm_mday ++;
			break;
	    case SOONEST:
			if ( (at->month >= 0) && (at->month < t->tm_mon) ) {
			    t->tm_year++;
			    t->tm_mon = at->month;
			    if ( at->day > 0 ) t->tm_mday = at->day;
			}
			else if ( (at->day > 0) && (at->day < t->tm_mday) ) {
			    if ( at->month >= 0 ) t->tm_mon = at->month + 1;
			    t->tm_mday = at->day;
			}
			else {
			    if ( at->month >= 0 ) t->tm_mon = at->month;
			    if ( at->day > 0 ) t->tm_mday = at->day;
			    if ( at_tod < tm_tod ) t->tm_mday ++;
			}
			break;
	    }
	    break;
    case OFFSET:
	    t->tm_hour = at->hour;
	    t->tm_min = at->minute;
    case EXACT_OFFSET:
	    offset(at,t);
	    break;
    }
    madetime = mktime(t);

    if (madetime < now) {
	fprintf(stderr, "trying to travel back in time\n");
	dump(at);
	exit(1);
    }
    return madetime;
}

int
main(argc, argv)
char **argv;
{
    atjobtime at;
    time_t jobtime;
    int i;

    if ( argc <= 1 )
       exit(1);
       
    if ( yy_prepare(&at, argc-1, argv+1) > 0 ) {
       yyparse();

       jobtime = maketime(&at);

       if (getenv("DEBUG_AT") == 0)
	   puts(ctime(&jobtime));
       exit(0);
    }
    perror("yy_prepare");
    exit(1);
}
