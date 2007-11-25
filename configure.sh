#! /bin/sh

# local options:  ac_help is the help message that describes them
# and LOCAL_AC_OPTIONS is the script that interprets them.  LOCAL_AC_OPTIONS
# is a script that's processed with eval, so you need to be very careful to
# make certain that what you quote is what you want to quote.

ac_help='
--use-koenig-fmt	use koenig format filenames (qSSSSSDDDDDDDD)
--with-spooldir		where at jobs are spooled (/var/spool/cron/atjobs)'

# load in the configuration file
#
TARGET=at-lex-yacc
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
"") AC_DEFINE ATDIR \"/var/spool/cron/atjobs/\" ;;
/*) AC_DEFINE ATDIR \"${WITH_QUEUEDIR}/\"
    ;;
*)  AC_FAIL "The at spool directory [$WITH_QUEUEDIR] must be a full pathname."
    ;;
esac

AC_CHECK_FLOCK || AC_DEFINE NO_FLOCK

AC_CHECK_HEADERS pwd.h grp.h ctype.h

# compile a little test program that can handle the many permutations
# of a user/group combo, since there doesn't seem to be a clean way of
# doing it using just system level stuff.
#             username  (uid,gid of this user)
#             user.group (uid of user, gid of group)
#             user.number (uid of user, specified gid)
#             number.group (specified uid, gid of group)
#             number.number (specified uid, gid)
#
cat << \EOF > $$.c
#include <stdio.h>
#include <pwd.h>
#include <grp.h>
#include <sys/types.h>
#include <ctype.h>

main(int argc, char **argv)
{
    struct passwd *pwd;
    struct group *grp;

    char *p, *q;

    fprintf(stderr, "%s: UID/GID dumper for configure.sh\n", argv[0]);
    printf("av_UID=; av_GID=;\n");
    if (argc <= 1)
	exit(1);

    for (p = argv[1]; *p && (*p != ':') && (*p != '.'); ++p)
	;

    if (*p) {
	*p++ = 0;
	if ( pwd = getpwnam(argv[1]) )
	    printf("av_UID=%d;\n", pwd->pw_uid);
	else {
	    for (q=argv[1]; isdigit(*q); ++q)
		;
	    if (*q == 0)
		printf("av_UID=%s;\n", argv[1]);
	    else
		exit(1);
	}

	if ( grp = getgrnam(p) )
	    printf("av_GID=%d;\n", grp->gr_gid);
	else {
	    for (q=p; isdigit(*q); ++q)
		;
	    if (*q == 0)
		printf("av_GID=%s;\n", q);
	    else
		exit(1);
	}
    }
    else if (pwd = getpwnam(argv[1]) )
	printf("av_UID=%d;\nav_GID=%d;\n", pwd->pw_uid, pwd->pw_gid);
    else
	exit(1);
    exit(0);
}
EOF

$AC_CC -o uid $$.c
status=$?
rm -f $$.c
test $? -eq 0 || AC_FAIL "Could not compile UID/GID dumper"

AC_DEFINE MAX_USERLEN	16

eval `./uid nobody`
if [ "$av_UID" -a "$av_GID" ]; then
    AC_DEFINE NOBODY_UID	$av_UID
    AC_DEFINE NOBODY_GID	$av_GID
else
    AC_FAIL "The 'nobody' account does not exist"
fi

rm -f uid

[ "$OS_FREEBSD" -o "$OS_DRAGONFLY" ] || AC_CHECK_HEADERS malloc.h

AC_DEFINE CONFDIR '"'$AC_CONFDIR'"'

AC_OUTPUT Makefile
