#! /bin/sh

# local options:  ac_help is the help message that describes them
# and LOCAL_AC_OPTIONS is the script that interprets them.  LOCAL_AC_OPTIONS
# is a script that's processed with eval, so you need to be very careful to
# make certain that what you quote is what you want to quote.

ac_help='
--with-posix-at		be more comparable with the rest of the Unix world
--with-spooldir		where at jobs are spooled (/var/spool/cron/atjobs)'

# load in the configuration file
#
TARGET=libat
USE_MAILWRAPPERS=T
. ./configure.inc

AC_INIT $TARGET

AC_PROG_CC

echo "int phui;" > /tmp/ngc$$.c
if $AC_CC $AC_CFLAGS -Wno-parentheses -c -o /tmp/ngc$$.o /tmp/ngc$$.c; then
    TLOG "It looks like you are using gcc.  You have my deepest sympathies."
    GCC_NOT_C=1
    AC_DEFINE "GCC_NOT_C" "1"
    AC_CFLAGS="$AC_CFLAGS -Wno-parentheses"
fi
rm -f /tmp/ngc$$.o /tmp/ngc$$.c

case "$AC_CC $AC_CFLAGS" in
*-Wall*)    AC_DEFINE 'while(x)' 'while( (x) != 0 )'
	    AC_DEFINE 'if(x)' 'if( (x) != 0 )' ;;
esac

AC_C_VOLATILE
AC_C_CONST
AC_SCALAR_TYPES
AC_CHECK_HEADERS limits.h || AC_DEFINE "INT_MAX" "1<<((sizeof(int)*8)-1)"

AC_CHECK_ALLOCA || AC_FAIL "$TARGET requires alloca()"

AC_CHECK_FUNCS scandir || AC_FAIL "$TARGET requires scandir()"
AC_CHECK_FUNCS mmap || AC_FAIL "$TARGET requires mmap()"
AC_CHECK_FUNCS memstr

if ! AC_CHECK_TYPE socklen_t sys/types.h sys/socket.h; then
    AC_DEFINE socklen_t int
fi

# for basename
if AC_CHECK_FUNCS basename; then
    AC_CHECK_HEADERS libgen.h
fi

case "$WITH_SPOOLDIR" in
"") if [ "$WITH_POSIX_AT" ]; then
	AC_DEFINE ATDIR \"/var/spool/atjobs/\"
	AC_SUB	ATDIR /var/spool/atjobs/
    else
	AC_DEFINE ATDIR \"/var/spool/cron/atjobs/\"
	AC_SUB ATDIR /var/spool/cron/atjobs/
    fi ;;
/*) AC_DEFINE ATDIR \"${WITH_QUEUEDIR}/\"
    AC_SUB ATDIR ${WITH_QUEUEDIR}/
    ;;
*)  AC_FAIL "The at spool directory [$WITH_QUEUEDIR] must be a full pathname."
    ;;
esac

AC_CHECK_FLOCK || AC_DEFINE NO_FLOCK

AC_CHECK_HEADERS pwd.h grp.h ctype.h

TLOGN "searching for lex/flex runtime library"
if AC_LIBRARY yywrap -ll -lfl; then
    TLOG " (found" ${AC_LIBS}")"
else
    TLOG " (not found)"
    AC_FAIL "maketime requires lex/flex"
fi

[ "$OS_FREEBSD" -o "$OS_DRAGONFLY" ] || AC_CHECK_HEADERS malloc.h

AC_DEFINE CONFDIR '"'$AC_CONFDIR'"'

AC_OUTPUT Makefile atq.1
