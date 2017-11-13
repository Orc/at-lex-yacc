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
unset _MK_LIBRARIAN

case "$AC_CC $AC_CFLAGS" in
*-pedantic*);;
*)          AC_DEFINE 'while(x)' 'while( (x) != 0 )'
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
/*) AC_DEFINE ATDIR \"${WITH_SPOOLDIR}/\"
    AC_SUB ATDIR ${WITH_SPOOLDIR}/
    ;;
*)  AC_FAIL "The at spool directory [$WITH_SPOOLDIR] must be a full pathname."
    ;;
esac

AC_CHECK_FLOCK || AC_DEFINE NO_FLOCK

AC_CHECK_HEADERS pwd.h grp.h ctype.h

AC_LIBRARY yywrap -ll -lfl || AC_FAIL "maketime requires lex/flex"

[ "$OS_FREEBSD" -o "$OS_DRAGONFLY" ] || AC_CHECK_HEADERS malloc.h

AC_DEFINE CONFDIR '"'$AC_CONFDIR'"'

AC_OUTPUT Makefile atq.1 at.1 atrm.1
