typedef struct atjobtime {
    enum { OFFSET, EXACT_OFFSET, DATE } mode;
    int special;	/* TONIGHT, TOMORROW, TODAY */
    int minute, hour, day, month, year;
    int offset;
    int units;		/* MINUTE HOUR DAY WEEK MONTH YEAR */
    int plural;		/* <interval>(s) */
    int pm;		/* am or pm */
} atjobtime;

#define YYSTYPE int
