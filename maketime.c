/*
 * maketime() converts an arglist into a time_t
 */
#include <stdio.h>
#include <fcntl.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <stdarg.h>
#include <time.h>
#include <sys/types.h>
#include <pwd.h>
#include <unistd.h>
#include <ctype.h>

#include "at.h"
#include "y.tab.h"

/*
 * see if a token is pluralized or not.
 */
int
yy_plural(char *s)
{
    int len = strlen(s);

    return (len > 0) && (s[len-1] == 's');
}


/*
 * adjust the job time by the specified # of items
 */
static void
offset(atjobtime *at, struct tm *tm)
{
    if ( (at->offset == 1 && at->plural) || (at->offset != 1 && !at->plural) )
	at->abend("syntax error (pluralization)");
    
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


/*
 * parse an at time.
 */
time_t
maketime(int argc, char **argv, void (*abend)(char*,...))
{
    time_t now, madetime;
    struct tm *t;
    atjobtime at;

    if ( yy_prepare(&at, argc, argv, abend) <= 0 ) {
	(*abend)("%s", strerror(errno));
	return 0;
    }

    if (yyparse() != 0)
	return 0;

    if ( at.hour > (at.pm  ? 12 : 24) ) {
	at.abend("incorrect time of day");
	return 0;
    }

    if (at.pm == 2) at.hour += 12;

    time(&now);
    t = localtime(&now);

    /*t->tm_sec = 0;*/
    t->tm_isdst = -1;

    if (at.hour >= 0) t->tm_hour = at.hour;
    if (at.minute >= 0) t->tm_min = at.minute;
    if (at.day > 0) t->tm_mday = at.day;
    if (at.month > 0) t->tm_mon = at.month-1;
    if (at.year > 0) t->tm_year = at.year - 1900;

    if (at.units)
	offset(&at,t);

    switch (at.special) {
    case TODAY:	break;
    case DAYNAME:
		if ( t->tm_wday < at.value )
		    t->tm_mday += (at.value - t->tm_wday);
		else
		    t->tm_mday += 7 + (at.value - t->tm_wday);
		break;
    case YESTERDAY:
		t->tm_mday--;
		break;
    case TOMORROW:
		t->tm_mday++;
		break;
    case TONIGHT:
		if ( (at.pm != 2) && (at.hour < 6) )
		    t->tm_mday ++;
		break;
    default:	if (mktime(t) < now) {
		    if (at.year == 0) t->tm_year ++;
		    else  t->tm_mday ++;
		}
		break;
    }

    if ( (madetime = mktime(t)) >= now)
	return madetime;

    at.abend("cannot travel back in time");
    return 0;
} /* maketime */
