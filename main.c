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

    if (at->pm > 0) at->hour += 12;
    
    time(&now);
    t = localtime(&now);

    t->tm_sec = 0;
    t->tm_isdst = -1;

    switch (at->mode) {
    case DATE:
	    t->tm_hour = at->hour;
	    t->tm_min = at->minute;
	    t->tm_wday %= 7;
	    
	    switch (at->special) {
	    case TODAY:	break;
	    case WEEK:	t->tm_mday += (7+1)  - t->tm_wday;
			break;
	    case MONTH:	t->tm_mon ++;
			t->tm_mday = 1;
			break;
	    case YEAR:	t->tm_year ++;
			t->tm_mon = 0;
			t->tm_mday = 1;
			break;
	    case DAYNAME:
			if ( t->tm_wday < at->offset )
			    t->tm_mday += (at->offset - t->tm_wday);
			else
			    t->tm_mday += 7 - (at->offset - t->tm_wday);
			break;
	    case TOMORROW:
			t->tm_mday++;
			break;
	    case TONIGHT:
			if ( (at->pm <= 0) && (at->hour < 6) )
			    t->tm_mday ++;
			break;
	    case SOONEST:
			if ( mktime(t) < now )
			    t->tm_mday ++;
			break;
	    default:	t->tm_mday = at->day;
			if (at->month >= 0)
			    t->tm_mon = at->month;
			if ( at->year != -1 )
			    t->tm_year = at->year - 1900;
			else if ( mktime(t) < now )
			    t->tm_year ++;
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

	if (getenv("DEBUG_AT") == 0) {
	   fputs(ctime(&jobtime), stdout);
	}
	exit(0);
    }
    perror("yy_prepare");
    exit(1);
}
