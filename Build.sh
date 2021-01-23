#!/bin/sh
srcversion='$MirOS: src/bin/sleep/Build.sh,v 1.1 2021/01/23 03:36:58 tg Exp $'
#-
# Copyright (c) 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010,
#		2011, 2012, 2013, 2014, 2015, 2016, 2017, 2019,
#		2020, 2021
#	mirabilos <m@mirbsd.org>
#
# Provided that these terms and disclaimer and all copyright notices
# are retained or reproduced in an accompanying document, permission
# is granted to deal in this work without restriction, including un-
# limited rights to use, publicly perform, distribute, sell, modify,
# merge, give away, or sublicence.
#
# This work is provided "AS IS" and WITHOUT WARRANTY of any kind, to
# the utmost extent permitted by applicable law, neither express nor
# implied; without malicious intent or gross negligence. In no event
# may a licensor, author or contributor be held liable for indirect,
# direct, other damage, loss, or other issues arising in any way out
# of dealing in the work, even if advised of the possibility of such
# damage or existence of a defect, except proven that it results out
# of said person's immediate fault when using the work as intended.
#-
# People analysing the output must whitelist conftest.c for any kind
# of compiler warning checks (mirtoconf is by design not quiet).
#
# Used environment documentation is at the end of this file.

LC_ALL=C; LANGUAGE=C
export LC_ALL; unset LANGUAGE

case $ZSH_VERSION:$VERSION in
:zsh*) ZSH_VERSION=2 ;;
esac

if test -n "${ZSH_VERSION+x}" && (emulate sh) >/dev/null 2>&1; then
	emulate sh
	NULLCMD=:
fi

if test -d /usr/xpg4/bin/. >/dev/null 2>&1; then
	# Solaris: some of the tools have weird behaviour, use portable ones
	PATH=/usr/xpg4/bin:$PATH
	export PATH
fi

nl='
'
safeIFS='	'
safeIFS=" $safeIFS$nl"
IFS=$safeIFS
allu=QWERTYUIOPASDFGHJKLZXCVBNM
alll=qwertyuiopasdfghjklzxcvbnm
alln=0123456789
alls=______________________________________________________________

test_n() {
	test x"$1" = x"" || return 0
	return 1
}

test_z() {
	test x"$1" = x""
}

case `echo a | tr '\201' X` in
X)
	# EBCDIC build system
	lfcr='\n\r'
	;;
*)
	lfcr='\012\015'
	;;
esac

echo "For the build logs, demonstrate that /dev/null and /dev/tty exist:"
ls -l /dev/null /dev/tty

v() {
	$e "$*"
	eval "$@"
}

vv() {
	_c=$1
	shift
	$e "\$ $*" 2>&1
	eval "$@" >vv.out 2>&1
	sed "s^${_c} " <vv.out
}

vq() {
	eval "$@"
}

rmf() {
	for _f in "$@"; do
		case $_f in
		*.1|*.faq|*.ico) ;;
		*) rm -f "$_f" ;;
		esac
	done
}

tcfn=no
bi=
ui=
ao=
fx=
me=`basename "$0"`
orig_CFLAGS=$CFLAGS
phase=x

if test -t 1; then
	bi='[1m'
	ui='[4m'
	ao='[0m'
fi

upper() {
	echo :"$@" | sed 's/^://' | tr $alll $allu
}

# clean up after ac_testrun()
ac_testdone() {
	eval HAVE_$fu=$fv
	fr=no
	test 0 = $fv || fr=yes
	$e "$bi==> $fd...$ao $ui$fr$ao$fx"
	fx=
}

# ac_cache label: sets f, fu, fv?=0
ac_cache() {
	f=$1
	fu=`upper $f`
	eval fv=\$HAVE_$fu
	case $fv in
	0|1)
		fx=' (cached)'
		return 0
		;;
	esac
	fv=0
	return 1
}

# ac_testinit label [!] checkif[!]0 [setlabelifcheckis[!]0] useroutput
# returns 1 if value was cached/implied, 0 otherwise: call ac_testdone
ac_testinit() {
	if ac_cache $1; then
		test x"$2" = x"!" && shift
		test x"$2" = x"" || shift
		fd=${3-$f}
		ac_testdone
		return 1
	fi
	fc=0
	if test x"$2" = x""; then
		ft=1
	else
		if test x"$2" = x"!"; then
			fc=1
			shift
		fi
		eval ft=\$HAVE_`upper $2`
		shift
	fi
	fd=${3-$f}
	if test $fc = "$ft"; then
		fv=$2
		fx=' (implied)'
		ac_testdone
		return 1
	fi
	$e ... $fd
	return 0
}

# pipe .c | ac_test[n] [!] label [!] checkif[!]0 [setlabelifcheckis[!]0] useroutput
ac_testnnd() {
	if test x"$1" = x"!"; then
		fr=1
		shift
	else
		fr=0
	fi
	ac_testinit "$@" || return 1
	cat >conftest.c
	vv ']' "$CC $CFLAGS $CPPFLAGS $LDFLAGS $NOWARN conftest.c $LIBS $ccpr"
	test $tcfn = no && test -f a.out && tcfn=a.out
	test $tcfn = no && test -f a.exe && tcfn=a.exe
	test $tcfn = no && test -f conftest.exe && tcfn=conftest.exe
	test $tcfn = no && test -f conftest && tcfn=conftest
	if test -f $tcfn; then
		test 1 = $fr || fv=1
	else
		test 0 = $fr || fv=1
	fi
	vscan=
	if test $phase = u; then
		test $ct = gcc && vscan='unrecogni[sz]ed'
		test $ct = hpcc && vscan='unsupported'
		test $ct = pcc && vscan='unsupported'
		test $ct = sunpro && vscan='-e ignored -e turned.off'
	fi
	test_n "$vscan" && grep $vscan vv.out >/dev/null 2>&1 && fv=$fr
	return 0
}
ac_testn() {
	ac_testnnd "$@" || return
	rmf conftest.c conftest.o ${tcfn}* vv.out
	ac_testdone
}

# ac_ifcpp cppexpr [!] label [!] checkif[!]0 [setlabelifcheckis[!]0] useroutput
ac_ifcpp() {
	expr=$1; shift
	ac_testn "$@" <<-EOF
		#include <unistd.h>
		extern int thiswillneverbedefinedIhope(void);
		int main(void) { return (isatty(0) +
		#$expr
		    0
		#else
		/* force a failure: expr is false */
		    thiswillneverbedefinedIhope()
		#endif
		    ); }
EOF
	test x"$1" = x"!" && shift
	f=$1
	fu=`upper $f`
	eval fv=\$HAVE_$fu
	test x"$fv" = x"1"
}

add_cppflags() {
	CPPFLAGS="$CPPFLAGS $*"
}

ac_cppflags() {
	test x"$1" = x"" || fu=$1
	fv=$2
	test x"$2" = x"" && eval fv=\$HAVE_$fu
	add_cppflags -DHAVE_$fu=$fv
}

ac_test() {
	ac_testn "$@"
	ac_cppflags
}

# ac_flags [-] add varname cflags [text] [ldflags]
ac_flags() {
	if test x"$1" = x"-"; then
		shift
		hf=1
	else
		hf=0
	fi
	fa=$1
	vn=$2
	f=$3
	ft=$4
	fl=$5
	test x"$ft" = x"" && ft="if $f can be used"
	save_CFLAGS=$CFLAGS
	CFLAGS="$CFLAGS $f"
	save_LDFLAGS=$LDFLAGS
	test_z "$fl" || LDFLAGS="$LDFLAGS $fl"
	if test 1 = $hf; then
		ac_testn can_$vn '' "$ft"
	else
		ac_testn can_$vn '' "$ft" <<-'EOF'
			/* evil apo'stroph in comment test */
			#include <unistd.h>
			int main(void) { return (isatty(0)); }
		EOF
		#'
	fi
	eval fv=\$HAVE_CAN_`upper $vn`
	test_z "$fl" || test 11 = $fa$fv || LDFLAGS=$save_LDFLAGS
	test 11 = $fa$fv || CFLAGS=$save_CFLAGS
}

# ac_header [!] header [prereq ...]
ac_header() {
	if test x"$1" = x"!"; then
		na=1
		shift
	else
		na=0
	fi
	hf=$1; shift
	hv=`echo "$hf" | tr -d "$lfcr" | tr -c $alll$allu$alln $alls`
	echo "/* NeXTstep bug workaround */" >x
	for i
	do
		case $i in
		_time)
			echo '#if HAVE_BOTH_TIME_H' >>x
			echo '#include <sys/time.h>' >>x
			echo '#include <time.h>' >>x
			echo '#elif HAVE_SYS_TIME_H' >>x
			echo '#include <sys/time.h>' >>x
			echo '#elif HAVE_TIME_H' >>x
			echo '#include <time.h>' >>x
			echo '#endif' >>x
			;;
		*)
			echo "#include <$i>" >>x
			;;
		esac
	done
	echo "#include <$hf>" >>x
	echo '#include <unistd.h>' >>x
	echo 'int main(void) { return (isatty(0)); }' >>x
	ac_testn "$hv" "" "<$hf>" <x
	rmf x
	test 1 = $na || ac_cppflags
}

addsrcs() {
	if test x"$1" = x"!"; then
		fr=0
		shift
	else
		fr=1
	fi
	eval i=\$$1
	test $fr = "$i" && case " $SRCS " in
	*\ $2\ *)	;;
	*)		SRCS="$SRCS $2" ;;
	esac
}


curdir=`pwd` srcdir=`dirname "$0" 2>/dev/null`
case x$srcdir in
x)
	srcdir=.
	;;
*\ *|*"	"*|*"$nl"*)
	echo >&2 Source directory should not contain space or tab or newline.
	echo >&2 Errors may occur.
	;;
*"'"*)
	echo Source directory must not contain single quotes.
	exit 1
	;;
esac

e=echo
r=0
eq=0
pm=0
cm=normal
optflags=-std-compile-opts
last=

for i
do
	case $last:$i in
	c:dragonegg|c:llvm)
		cm=$i
		last=
		;;
	c:*)
		echo "$me: Unknown option -c '$i'!" >&2
		exit 1
		;;
	o:*)
		optflags=$i
		last=
		;;
	:-c)
		last=c
		;;
	:-g)
		# checker, debug, valgrind build
		add_cppflags -DDEBUG
		CFLAGS="$CFLAGS -g3 -fno-builtin"
		;;
	:-j)
		pm=1
		;;
	:-M)
		cm=makefile
		;;
	:-O)
		optflags=-std-compile-opts
		;;
	:-o)
		last=o
		;;
	:-Q)
		eq=1
		;;
	:-r)
		r=1
		;;
	:-v)
		echo "Build.sh $srcversion"
		echo "for MirBSD sleep"
		exit 0
		;;
	:*)
		echo "$me: Unknown option '$i'!" >&2
		exit 1
		;;
	*)
		echo "$me: Unknown option -'$last' '$i'!" >&2
		exit 1
		;;
	esac
done
if test_n "$last"; then
	echo "$me: Option -'$last' not followed by argument!" >&2
	exit 1
fi

tfn=sleep
if test -d $tfn || test -d $tfn.exe; then
	echo "$me: Error: ./$tfn is a directory!" >&2
	exit 1
fi
rmf a.exe* a.out* conftest.c conftest.exe* *core core.* ${tfn}* *.bc *.dbg \
    *.ll *.o *.cat1 Rebuild.sh lft no x vv.out

SRCS="sleep.c"

if test x"$srcdir" = x"."; then
	CPPFLAGS="-I. $CPPFLAGS"
else
	CPPFLAGS="-I. -I'$srcdir' $CPPFLAGS"
fi
test_z "$LDSTATIC" || if test_z "$LDFLAGS"; then
	LDFLAGS=$LDSTATIC
else
	LDFLAGS="$LDFLAGS $LDSTATIC"
fi

if test_z "$TARGET_OS"; then
	x=`uname -s 2>/dev/null || uname`
	test x"$x" = x"`uname -n 2>/dev/null`" || TARGET_OS=$x
fi
if test_z "$TARGET_OS"; then
	echo "$me: Set TARGET_OS, your uname is broken!" >&2
	exit 1
fi
oswarn=
ccpc=-Wc,
ccpl=-Wl,
tsts=
ccpr='|| for _f in ${tcfn}*; do case $_f in *.1|*.faq|*.ico) ;; *) rm -f "$_f" ;; esac; done'

# Evil hack
if test x"$TARGET_OS" = x"Android"; then
	TARGET_OS=Linux
fi

# Evil OS
if test x"$TARGET_OS" = x"Minix"; then
	echo >&2 "
WARNING: additional checks before running Build.sh required!
You can avoid these by calling Build.sh correctly, see below.
"
	cat >conftest.c <<'EOF'
#include <sys/types.h>
const char *
#ifdef _NETBSD_SOURCE
ct="Ninix3"
#else
ct="Minix3"
#endif
;
EOF
	ct=unknown
	vv ']' "${CC-cc} -E $CFLAGS $CPPFLAGS $NOWARN conftest.c | grep ct= | tr -d \\\\015 >x"
	sed 's/^/[ /' x
	eval `cat x`
	rmf x vv.out
	case $ct in
	Minix3|Ninix3)
		echo >&2 "
Warning: you set TARGET_OS to $TARGET_OS but that is ambiguous.
Please set it to either Minix3 or Ninix3, whereas the latter is
all versions of Minix with even partial NetBSD(R) userland. The
value determined from your compiler for the current compilation
(which may be wrong) is: $ct
"
		TARGET_OS=$ct
		;;
	*)
		echo >&2 "
Warning: you set TARGET_OS to $TARGET_OS but that is ambiguous.
Please set it to either Minix3 or Ninix3, whereas the latter is
all versions of Minix with even partial NetBSD(R) userland. The
proper value couldn't be determined, continue at your own risk.
"
		;;
	esac
fi

# Configuration depending on OS revision, on OSes that need them
case $TARGET_OS in
SCO_SV)
	test_n "$TARGET_OSREV" || TARGET_OSREV=`uname -r`
	;;
esac

# Configuration depending on OS name
case $TARGET_OS in
CYGWIN*)
	;;
Darwin)
	add_cppflags -D_DARWIN_C_SOURCE
	;;
DragonFly)
	;;
FreeBSD)
	;;
GNU)
	case $CC in
	*tendracc*) ;;
	*) add_cppflags -D_GNU_SOURCE ;;
	esac
	;;
GNU/kFreeBSD)
	case $CC in
	*tendracc*) ;;
	*) add_cppflags -D_GNU_SOURCE ;;
	esac
	;;
Linux)
	case $CC in
	*tendracc*) ;;
	*) add_cppflags -D_GNU_SOURCE ;;
	esac
	;;
MidnightBSD)
	;;
MirBSD)
	;;
NetBSD)
	;;
OpenBSD)
	;;
*)
	oswarn='; it is untested but should work'
	test_n "$TARGET_OSREV" || TARGET_OSREV=`uname -r`
	;;
esac

: "${CC=cc}${NROFF=nroff}${SIZE=size}"
test 0 = $r && echo | $NROFF -v 2>&1 | grep GNU >/dev/null 2>&1 && \
    echo | $NROFF -c >/dev/null 2>&1 && NROFF="$NROFF -c"

# this aids me in tracing FTBFSen without access to the buildd
$e "Hi from$ao $bi$srcversion$ao on:"
case $TARGET_OS in
AIX)
	vv '|' "oslevel >&2"
	vv '|' "uname -a >&2"
	;;
Darwin)
	vv '|' "hwprefs machine_type os_type os_class >&2"
	vv '|' "sw_vers >&2"
	vv '|' "system_profiler -detailLevel mini SPSoftwareDataType SPHardwareDataType >&2"
	vv '|' "/bin/sh --version >&2"
	vv '|' "xcodebuild -version >&2"
	vv '|' "uname -a >&2"
	vv '|' "sysctl kern.version hw.machine hw.model hw.memsize hw.availcpu hw.ncpu hw.cpufrequency hw.byteorder hw.cpu64bit_capable >&2"
	vv '|' "sysctl hw.cpufrequency hw.byteorder hw.cpu64bit_capable hw.ncpu >&2"
	;;
IRIX*)
	vv '|' "uname -a >&2"
	vv '|' "hinv -v >&2"
	;;
OSF1)
	vv '|' "uname -a >&2"
	vv '|' "/usr/sbin/sizer -v >&2"
	;;
SCO_SV|UnixWare|UNIX_SV)
	vv '|' "uname -a >&2"
	vv '|' "uname -X >&2"
	;;
*)
	vv '|' "uname -a >&2"
	;;
esac
test_z "$oswarn" || echo >&2 "
Warning: sleep has not yet been ported to or tested on your
operating system '$TARGET_OS'$oswarn. If you can provide
a shell account to the developer, this may improve; please
drop us a success or failure notice or even send in diffs,
at the very least, complete logs (Build.sh + test?) will help.
"
$e "$bi$me: Building MirBSD sleep$ao on $TARGET_OS ${TARGET_OSREV}..."

#
# Start of mirtoconf checks
#
$e $bi$me: Scanning for functions... please ignore any errors.$ao

#
# Compiler: which one?
#
# notes:
# - ICC defines __GNUC__ too
# - GCC defines __hpux too
# - LLVM+clang defines __GNUC__ too
# - nwcc defines __GNUC__ too
CPP="$CC -E"
$e ... which compiler type seems to be used
cat >conftest.c <<'EOF'
const char *
#if defined(__ICC) || defined(__INTEL_COMPILER)
ct="icc"
#elif defined(__xlC__) || defined(__IBMC__)
ct="xlc"
#elif defined(__SUNPRO_C)
ct="sunpro"
#elif defined(__neatcc__)
ct="neatcc"
#elif defined(__lacc__)
ct="lacc"
#elif defined(__ACK__)
ct="ack"
#elif defined(__BORLANDC__)
ct="bcc"
#elif defined(__WATCOMC__)
ct="watcom"
#elif defined(__MWERKS__)
ct="metrowerks"
#elif defined(__HP_cc)
ct="hpcc"
#elif defined(__DECC) || (defined(__osf__) && !defined(__GNUC__))
ct="dec"
#elif defined(__PGI)
ct="pgi"
#elif defined(__DMC__)
ct="dmc"
#elif defined(_MSC_VER)
ct="msc"
#elif defined(__ADSPBLACKFIN__) || defined(__ADSPTS__) || defined(__ADSP21000__)
ct="adsp"
#elif defined(__IAR_SYSTEMS_ICC__)
ct="iar"
#elif defined(SDCC)
ct="sdcc"
#elif defined(__PCC__)
ct="pcc"
#elif defined(__TenDRA__)
ct="tendra"
#elif defined(__TINYC__)
ct="tcc"
#elif defined(__llvm__) && defined(__clang__)
ct="clang"
#elif defined(__NWCC__)
ct="nwcc"
#elif defined(__GNUC__)
ct="gcc"
#elif defined(_COMPILER_VERSION)
ct="mipspro"
#elif defined(__sgi)
ct="mipspro"
#elif defined(__hpux) || defined(__hpua)
ct="hpcc"
#elif defined(__ultrix)
ct="ucode"
#elif defined(__USLC__)
ct="uslc"
#elif defined(__LCC__)
ct="lcc"
#elif defined(MKSH_MAYBE_KENCC)
/* and none of the above matches */
ct="kencc"
#else
ct="unknown"
#endif
;
const char *
#if defined(__KLIBC__) && !defined(__OS2__)
et="klibc"
#else
et="unknown"
#endif
;
EOF
ct=untested
et=untested
vv ']' "$CPP $CFLAGS $CPPFLAGS $NOWARN conftest.c | \
    sed -n '/^ *[ce]t *= */s/^ *\([ce]t\) *= */\1=/p' | tr -d \\\\015 >x"
sed 's/^/[ /' x
eval `cat x`
rmf x vv.out
cat >conftest.c <<'EOF'
#include <unistd.h>
int main(void) { return (isatty(0)); }
EOF
case $ct in
ack)
	# work around "the famous ACK const bug"
	CPPFLAGS="-Dconst= $CPPFLAGS"
	;;
adsp)
	echo >&2 'Warning: Analog Devices C++ compiler for Blackfin, TigerSHARC
    and SHARC (21000) DSPs detected. This compiler has not yet
    been tested for compatibility with this. Continue at your
    own risk, please report success/failure to the developers.'
	;;
bcc)
	echo >&2 "Warning: Borland C++ Builder detected. This compiler might
    produce broken executables. Continue at your own risk,
    please report success/failure to the developers."
	;;
clang)
	# does not work with current "ccc" compiler driver
	vv '|' "$CC $CFLAGS $CPPFLAGS $LDFLAGS $NOWARN $LIBS -version"
	# one of these two works, for now
	vv '|' "${CLANG-clang} -version"
	vv '|' "${CLANG-clang} --version"
	# ensure compiler and linker are in sync unless overridden
	case $CCC_CC:$CCC_LD in
	:*)	;;
	*:)	CCC_LD=$CCC_CC; export CCC_LD ;;
	esac
	;;
dec)
	vv '|' "$CC $CFLAGS $CPPFLAGS $LDFLAGS $NOWARN $LIBS -V"
	vv '|' "$CC $CFLAGS $CPPFLAGS $LDFLAGS $NOWARN -Wl,-V conftest.c $LIBS"
	;;
gcc)
	vv '|' "$CC $CFLAGS $CPPFLAGS $LDFLAGS $NOWARN -v conftest.c $LIBS"
	vv '|' 'eval echo "\`$CC $CFLAGS $CPPFLAGS $LDFLAGS $NOWARN $LIBS -dumpmachine\`" \
		 "gcc\`$CC $CFLAGS $CPPFLAGS $LDFLAGS $NOWARN $LIBS -dumpversion\`"'
	;;
hpcc)
	vv '|' "$CC $CFLAGS $CPPFLAGS $LDFLAGS $NOWARN -V conftest.c $LIBS"
	;;
iar)
	echo >&2 'Warning: IAR Systems (http://www.iar.com) compiler for embedded
    systems detected. This unsupported compiler has not yet
    been tested for compatibility with this. Continue at your
    own risk, please report success/failure to the developers.'
	;;
icc)
	vv '|' "$CC $CFLAGS $CPPFLAGS $LDFLAGS $NOWARN $LIBS -V"
	;;
kencc)
	vv '|' "$CC $CFLAGS $CPPFLAGS $LDFLAGS $NOWARN -v conftest.c $LIBS"
	;;
lacc)
	# no version information
	;;
lcc)
	vv '|' "$CC $CFLAGS $CPPFLAGS $LDFLAGS $NOWARN -v conftest.c $LIBS"
	add_cppflags -D__inline__=__inline
	;;
metrowerks)
	echo >&2 'Warning: Metrowerks C compiler detected. This has not yet
    been tested for compatibility with this. Continue at your
    own risk, please report success/failure to the developers.'
	;;
mipspro)
	vv '|' "$CC $CFLAGS $CPPFLAGS $LDFLAGS $NOWARN $LIBS -version"
	;;
msc)
	ccpr=		# errorlevels are not reliable
	case $TARGET_OS in
	Interix)
		if test_z "$C89_COMPILER"; then
			C89_COMPILER=CL.EXE
		else
			C89_COMPILER=`ntpath2posix -c "$C89_COMPILER"`
		fi
		if test_z "$C89_LINKER"; then
			C89_LINKER=LINK.EXE
		else
			C89_LINKER=`ntpath2posix -c "$C89_LINKER"`
		fi
		vv '|' "$C89_COMPILER /HELP >&2"
		vv '|' "$C89_LINKER /LINK >&2"
		;;
	esac
	;;
neatcc)
	add_cppflags -DMKSH_DONT_EMIT_IDSTRING
	vv '|' "$CC"
	;;
nwcc)
	vv '|' "$CC $CFLAGS $CPPFLAGS $LDFLAGS $NOWARN $LIBS -version"
	;;
pcc)
	vv '|' "$CC $CFLAGS $CPPFLAGS $LDFLAGS $NOWARN $LIBS -v"
	;;
pgi)
	echo >&2 'Warning: PGI detected. This unknown compiler has not yet
    been tested for compatibility with this. Continue at your
    own risk, please report success/failure to the developers.'
	;;
sdcc)
	echo >&2 'Warning: sdcc (http://sdcc.sourceforge.net), the small devices
    C compiler for embedded systems detected. This has not yet
    been tested for compatibility with this. Continue at your
    own risk, please report success/failure to the developers.'
	;;
sunpro)
	vv '|' "$CC $CFLAGS $CPPFLAGS $LDFLAGS $NOWARN -V conftest.c $LIBS"
	;;
tcc)
	vv '|' "$CC $CFLAGS $CPPFLAGS $LDFLAGS $NOWARN $LIBS -v"
	;;
tendra)
	vv '|' "$CC $CFLAGS $CPPFLAGS $LDFLAGS $NOWARN $LIBS -V 2>&1 | \
	    grep -F -i -e version -e release"
	;;
ucode)
	vv '|' "$CC $CFLAGS $CPPFLAGS $LDFLAGS $NOWARN $LIBS -V"
	vv '|' "$CC $CFLAGS $CPPFLAGS $LDFLAGS $NOWARN -Wl,-V conftest.c $LIBS"
	;;
uslc)
	case $TARGET_OS:$TARGET_OSREV in
	SCO_SV:3.2*)
		# SCO OpenServer 5
		CFLAGS="$CFLAGS -g"
		: "${HAVE_CAN_OTWO=0}${HAVE_CAN_OPTIMISE=0}"
		;;
	esac
	vv '|' "$CC $CFLAGS $CPPFLAGS $LDFLAGS $NOWARN -V conftest.c $LIBS"
	;;
watcom)
	vv '|' "$CC $CFLAGS $CPPFLAGS $LDFLAGS $NOWARN -v conftest.c $LIBS"
	;;
xlc)
	vv '|' "$CC $CFLAGS $CPPFLAGS $LDFLAGS $NOWARN $LIBS -qversion"
	vv '|' "$CC $CFLAGS $CPPFLAGS $LDFLAGS $NOWARN $LIBS -qversion=verbose"
	vv '|' "ld -V"
	;;
*)
	test x"$ct" = x"untested" && $e "!!! detecting preprocessor failed"
	ct=unknown
	vv '|' "$CC --version"
	vv '|' "$CC $CFLAGS $CPPFLAGS $LDFLAGS $NOWARN -v conftest.c $LIBS"
	vv '|' "$CC $CFLAGS $CPPFLAGS $LDFLAGS $NOWARN -V conftest.c $LIBS"
	;;
esac
case $cm in
dragonegg|llvm)
	vv '|' "llc -version"
	;;
esac
etd=" on $et"
case $et in
klibc)
	;;
unknown)
	# nothing special detected, don’t worry
	etd=
	;;
*)
	# huh?
	;;
esac
$e "$bi==> which compiler type seems to be used...$ao $ui$ct$etd$ao"
rmf conftest.c conftest.o conftest a.out* a.exe* conftest.exe* vv.out

#
# Compiler: works as-is, with -Wno-error and -Werror
#
save_NOWARN=$NOWARN
NOWARN=
DOWARN=
ac_flags 0 compiler_works '' 'if the compiler works'
test 1 = $HAVE_CAN_COMPILER_WORKS || exit 1
HAVE_COMPILER_KNOWN=0
test $ct = unknown || HAVE_COMPILER_KNOWN=1
if ac_ifcpp 'if 0' compiler_fails '' \
    'if the compiler does not fail correctly'; then
	save_CFLAGS=$CFLAGS
	: "${HAVE_CAN_DELEXE=x}"
	case $ct in
	dec)
		CFLAGS="$CFLAGS ${ccpl}-non_shared"
		ac_testn can_delexe compiler_fails 0 'for the -non_shared linker option' <<-'EOF'
			#include <unistd.h>
			int main(void) { return (isatty(0)); }
		EOF
		;;
	dmc)
		CFLAGS="$CFLAGS ${ccpl}/DELEXECUTABLE"
		ac_testn can_delexe compiler_fails 0 'for the /DELEXECUTABLE linker option' <<-'EOF'
			#include <unistd.h>
			int main(void) { return (isatty(0)); }
		EOF
		;;
	*)
		exit 1
		;;
	esac
	test 1 = $HAVE_CAN_DELEXE || CFLAGS=$save_CFLAGS
	ac_ifcpp 'if 0' compiler_still_fails \
	    'if the compiler still does not fail correctly' && exit 1
fi
if ac_ifcpp 'ifdef __TINYC__' couldbe_tcc '!' compiler_known 0 \
    'if this could be tcc'; then
	ct=tcc
	CPP='cpp -D__TINYC__'
	HAVE_COMPILER_KNOWN=1
fi

case $ct in
bcc)
	save_NOWARN="${ccpc}-w"
	DOWARN="${ccpc}-w!"
	;;
dec)
	# -msg_* flags not used yet, or is -w2 correct?
	;;
dmc)
	save_NOWARN="${ccpc}-w"
	DOWARN="${ccpc}-wx"
	;;
hpcc)
	save_NOWARN=
	DOWARN=+We
	;;
kencc)
	save_NOWARN=
	DOWARN=
	;;
mipspro)
	save_NOWARN=
	DOWARN="-diag_error 1-10000"
	;;
msc)
	save_NOWARN="${ccpc}/w"
	DOWARN="${ccpc}/WX"
	;;
sunpro)
	test x"$save_NOWARN" = x"" && save_NOWARN='-errwarn=%none'
	ac_flags 0 errwarnnone "$save_NOWARN"
	test 1 = $HAVE_CAN_ERRWARNNONE || save_NOWARN=
	ac_flags 0 errwarnall "-errwarn=%all"
	test 1 = $HAVE_CAN_ERRWARNALL && DOWARN="-errwarn=%all"
	;;
tendra)
	save_NOWARN=-w
	;;
ucode)
	save_NOWARN=
	DOWARN=-w2
	;;
watcom)
	save_NOWARN=
	DOWARN=-Wc,-we
	;;
xlc)
	case $TARGET_OS in
	OS/390)
		save_NOWARN=-qflag=e
		DOWARN=-qflag=i
		;;
	*)
		save_NOWARN=-qflag=i:e
		DOWARN=-qflag=i:i
		;;
	esac
	;;
*)
	test x"$save_NOWARN" = x"" && save_NOWARN=-Wno-error
	ac_flags 0 wnoerror "$save_NOWARN"
	test 1 = $HAVE_CAN_WNOERROR || save_NOWARN=
	ac_flags 0 werror -Werror
	test 1 = $HAVE_CAN_WERROR && DOWARN=-Werror
	test $ct = icc && DOWARN="$DOWARN -wd1419"
	;;
esac
NOWARN=$save_NOWARN

#
# Compiler: extra flags (-O2 -f* -W* etc.)
#
i=`echo :"$orig_CFLAGS" | sed 's/^://' | tr -c -d $alll$allu$alln`
# optimisation: only if orig_CFLAGS is empty
test_n "$i" || case $ct in
hpcc)
	phase=u
	ac_flags 1 otwo +O2
	phase=x
	;;
kencc|tcc|tendra)
	# no special optimisation
	;;
sunpro)
	cat >x <<-'EOF'
		#include <unistd.h>
		int main(void) { return (isatty(0)); }
		#define __IDSTRING_CONCAT(l,p)	__LINTED__ ## l ## _ ## p
		#define __IDSTRING_EXPAND(l,p)	__IDSTRING_CONCAT(l,p)
		#define pad			void __IDSTRING_EXPAND(__LINE__,x)(void) { }
	EOF
	yes pad | head -n 256 >>x
	ac_flags - 1 otwo -xO2 <x
	rmf x
	;;
xlc)
	ac_flags 1 othree "-O3 -qstrict"
	test 1 = $HAVE_CAN_OTHREE || ac_flags 1 otwo -O2
	;;
*)
	ac_flags 1 otwo -O2
	test 1 = $HAVE_CAN_OTWO || ac_flags 1 optimise -O
	;;
esac
# other flags: just add them if they are supported
i=0
case $ct in
bcc)
	ac_flags 1 strpool "${ccpc}-d" 'if string pooling can be enabled'
	;;
clang)
	i=1
	;;
dec)
	ac_flags 0 verb -verbose
	ac_flags 1 rodata -readonly_strings
	;;
dmc)
	ac_flags 1 decl "${ccpc}-r" 'for strict prototype checks'
	ac_flags 1 schk "${ccpc}-s" 'for stack overflow checking'
	;;
gcc)
	ac_flags 1 fnolto -fno-lto 'whether we can explicitly disable buggy GCC LTO' -fno-lto
	# The following tests run with -Werror (gcc only) if possible
	NOWARN=$DOWARN; phase=u
	# MirBSD utilities are not written in CFrustFrust!
	ac_flags 1 no_eh_frame -fno-asynchronous-unwind-tables
	ac_flags 1 fnostrictaliasing -fno-strict-aliasing
	ac_flags 1 fstackprotectorstrong -fstack-protector-strong
	test 1 = $HAVE_CAN_FSTACKPROTECTORSTRONG || \
	    ac_flags 1 fstackprotectorall -fstack-protector-all
	test $cm = dragonegg && case " $CC $CFLAGS $LDFLAGS " in
	*\ -fplugin=*dragonegg*) ;;
	*) ac_flags 1 fplugin_dragonegg -fplugin=dragonegg ;;
	esac
	case $cm in
	combine)
		fv=0
		checks='7 8'
		;;
	lto)
		fv=0
		checks='1 2 3 4 5 6 7 8'
		;;
	*)
		fv=1
		;;
	esac
	test $fv = 1 || for what in $checks; do
		test $fv = 1 && break
		case $what in
		1)	t_cflags='-flto=jobserver'
			t_ldflags='-fuse-linker-plugin'
			t_use=1 t_name=fltojs_lp ;;
		2)	t_cflags='-flto=jobserver' t_ldflags=''
			t_use=1 t_name=fltojs_nn ;;
		3)	t_cflags='-flto=jobserver'
			t_ldflags='-fno-use-linker-plugin -fwhole-program'
			t_use=1 t_name=fltojs_np ;;
		4)	t_cflags='-flto'
			t_ldflags='-fuse-linker-plugin'
			t_use=1 t_name=fltons_lp ;;
		5)	t_cflags='-flto' t_ldflags=''
			t_use=1 t_name=fltons_nn ;;
		6)	t_cflags='-flto'
			t_ldflags='-fno-use-linker-plugin -fwhole-program'
			t_use=1 t_name=fltons_np ;;
		7)	t_cflags='-fwhole-program --combine' t_ldflags=''
			t_use=0 t_name=combine cm=combine ;;
		8)	fv=1 cm=normal ;;
		esac
		test $fv = 1 && break
		ac_flags $t_use $t_name "$t_cflags" \
		    "if gcc supports $t_cflags $t_ldflags" "$t_ldflags"
	done
	ac_flags 1 data_abi_align -malign-data=abi
	i=1
	;;
hpcc)
	phase=u
	# probably not needed
	#ac_flags 1 agcc -Agcc 'for support of GCC extensions'
	phase=x
	;;
icc)
	ac_flags 1 fnobuiltinsetmode -fno-builtin-setmode
	ac_flags 1 fnostrictaliasing -fno-strict-aliasing
	ac_flags 1 fstacksecuritycheck -fstack-security-check
	i=1
	;;
mipspro)
	ac_flags 1 fullwarn -fullwarn 'for remark output support'
	;;
msc)
	ac_flags 1 strpool "${ccpc}/GF" 'if string pooling can be enabled'
	echo 'int main(void) { char test[64] = ""; return (*test); }' >x
	ac_flags - 1 stackon "${ccpc}/GZ" 'if stack checks can be enabled' <x
	ac_flags - 1 stckall "${ccpc}/Ge" 'stack checks for all functions' <x
	ac_flags - 1 secuchk "${ccpc}/GS" 'for compiler security checks' <x
	rmf x
	ac_flags 1 wall "${ccpc}/Wall" 'to enable all warnings'
	ac_flags 1 wp64 "${ccpc}/Wp64" 'to enable 64-bit warnings'
	;;
nwcc)
	#broken# ac_flags 1 ssp -stackprotect
	i=1
	;;
pcc)
	ac_flags 1 fstackprotectorall -fstack-protector-all
	i=1
	;;
sunpro)
	phase=u
	ac_flags 1 v -v
	ac_flags 1 ipo -xipo 'for cross-module optimisation'
	phase=x
	;;
tcc)
	: #broken# ac_flags 1 boundschk -b
	;;
tendra)
	ac_flags 0 ysystem -Ysystem
	test 1 = $HAVE_CAN_YSYSTEM && CPPFLAGS="-Ysystem $CPPFLAGS"
	ac_flags 1 extansi -Xa
	;;
xlc)
	case $TARGET_OS in
	OS/390)
		# On IBM z/OS, the following are warnings by default:
		# CCN3296: #include file <foo.h> not found.
		# CCN3944: Attribute "__foo__" is not supported and is ignored.
		# CCN3963: The attribute "foo" is not a valid variable attribute and is ignored.
		ac_flags 1 halton '-qhaltonmsg=CCN3296 -qhaltonmsg=CCN3944 -qhaltonmsg=CCN3963'
		# CCN3290: Unknown macro name FOO on #undef directive.
		# CCN4108: The use of keyword '__attribute__' is non-portable.
		ac_flags 1 supprss '-qsuppress=CCN3290 -qsuppress=CCN4108'
		;;
	*)
		ac_flags 1 rodata '-qro -qroconst -qroptr'
		ac_flags 1 rtcheck -qcheck=all
		#ac_flags 1 rtchkc -qextchk	# reported broken
		ac_flags 1 wformat '-qformat=all -qformat=nozln'
		;;
	esac
	#ac_flags 1 wp64 -qwarn64	# too verbose for now
	;;
esac
# flags common to a subset of compilers (run with -Werror on gcc)
if test 1 = $i; then
	ac_flags 1 wall -Wall
	ac_flags 1 fwrapv -fwrapv
fi

phase=x
# The following tests run with -Werror or similar (all compilers) if possible
NOWARN=$DOWARN
test $ct = pcc && phase=u

#
# Compiler: check for stuff that only generates warnings
#
ac_test attribute_format '' 'for __attribute__((__format__))' <<-'EOF'
	#if defined(__TenDRA__) || (defined(__GNUC__) && (__GNUC__ < 2))
	extern int thiswillneverbedefinedIhope(void);
	/* force a failure: TenDRA and gcc 1.42 have false positive here */
	int main(void) { return (thiswillneverbedefinedIhope()); }
	#else
	#define fprintf printfoo
	#include <stdio.h>
	#undef __attribute__
	#undef fprintf
	extern int fprintf(FILE *, const char *format, ...)
	    __attribute__((__format__(__printf__, 2, 3)));
	int main(int ac, char *av[]) { return (fprintf(stderr, "%s%d", *av, ac)); }
	#endif
EOF
ac_test attribute_noreturn '' 'for __attribute__((__noreturn__))' <<-'EOF'
	#if defined(__TenDRA__) || (defined(__GNUC__) && (__GNUC__ < 2))
	extern int thiswillneverbedefinedIhope(void);
	/* force a failure: TenDRA and gcc 1.42 have false positive here */
	int main(void) { return (thiswillneverbedefinedIhope()); }
	#else
	#include <stdlib.h>
	#undef __attribute__
	void fnord(void) __attribute__((__noreturn__));
	int main(void) { fnord(); }
	void fnord(void) { exit(0); }
	#endif
EOF
ac_test attribute_unused '' 'for __attribute__((__unused__))' <<-'EOF'
	#if defined(__TenDRA__) || (defined(__GNUC__) && (__GNUC__ < 2))
	extern int thiswillneverbedefinedIhope(void);
	/* force a failure: TenDRA and gcc 1.42 have false positive here */
	int main(void) { return (thiswillneverbedefinedIhope()); }
	#else
	#include <unistd.h>
	#undef __attribute__
	int main(int ac __attribute__((__unused__)), char *av[]
	    __attribute__((__unused__))) { return (isatty(0)); }
	#endif
EOF

# End of tests run with -Werror
NOWARN=$save_NOWARN
phase=x

#
# Environment: headers
#
ac_header sys/time.h sys/types.h
ac_header time.h sys/types.h
test "11" = "$HAVE_SYS_TIME_H$HAVE_TIME_H" || HAVE_BOTH_TIME_H=0
ac_test both_time_h '' 'whether <sys/time.h> and <time.h> can both be included' <<-'EOF'
	#include <sys/types.h>
	#include <sys/time.h>
	#include <time.h>
	#include <unistd.h>
	int main(void) { struct tm tm; return ((int)sizeof(tm) + isatty(0)); }
EOF
ac_header sys/bsdtypes.h
ac_header sys/param.h
ac_header sys/select.h sys/types.h
ac_header bstring.h
# include strings.h only if compatible with string.h
ac_header strings.h sys/types.h string.h

#
# Environment: definitions
#

#
# Environment: types
#

#
# check whether whatever we use for the final link will succeed
#
if test $cm = makefile; then
	: nothing to check
else
	HAVE_LINK_WORKS=x
	ac_testinit link_works '' 'checking if the final link command may succeed'
	fv=1
	cat >conftest.c <<-EOF
		#define EXTERN
		#include "sleep.h"
		__RCSID("$srcversion");
		int main(void) {
			struct timeval tv;
			return (select(0, NULL, NULL, NULL, &tv));
		}
EOF
	case $cm in
	llvm)
		v "$CC $CFLAGS $CPPFLAGS $NOWARN -emit-llvm -c conftest.c" || fv=0
		rmf $tfn.s
		test $fv = 0 || v "llvm-link -o - conftest.o | opt $optflags | llc -o $tfn.s" || fv=0
		test $fv = 0 || v "$CC $CFLAGS $LDFLAGS -o $tcfn $tfn.s $LIBS $ccpr"
		;;
	dragonegg)
		v "$CC $CFLAGS $CPPFLAGS $NOWARN -S -flto conftest.c" || fv=0
		test $fv = 0 || v "mv conftest.s conftest.ll"
		test $fv = 0 || v "llvm-as conftest.ll" || fv=0
		rmf $tfn.s
		test $fv = 0 || v "llvm-link -o - conftest.bc | opt $optflags | llc -o $tfn.s" || fv=0
		test $fv = 0 || v "$CC $CFLAGS $LDFLAGS -o $tcfn $tfn.s $LIBS $ccpr"
		;;
	combine)
		v "$CC $CFLAGS $CPPFLAGS $LDFLAGS -fwhole-program --combine $NOWARN -o $tcfn conftest.c $LIBS $ccpr"
		;;
	lto|normal)
		cm=normal
		v "$CC $CFLAGS $CPPFLAGS $NOWARN -c conftest.c" || fv=0
		test $fv = 0 || v "$CC $CFLAGS $LDFLAGS -o $tcfn conftest.o $LIBS $ccpr"
		;;
	esac
	test -f $tcfn || fv=0
	ac_testdone
	test $fv = 1 || exit 1
fi

#
# Environment: library functions
#
: notyet_sleepuntil ||\
ac_test gettimeofday <<-'EOF'
	#define MKSH_INCLUDES_ONLY
	#include "sh.h"
	int main(void) { struct timeval tv; return (gettimeofday(&tv, NULL)); }
EOF

ac_test strerror <<-'EOF'
	extern char *strerror(int);
	int main(int ac, char *av[]) { return (*strerror(*av[ac])); }
EOF

#
# check headers for declarations
#

#
# other checks
#

#
# Compiler: Praeprocessor (only if needed)
#

#
# End of mirtoconf checks
#
$e ... done.

test 1 = "$HAVE_CAN_VERB" && CFLAGS="$CFLAGS -verbose"

$e $bi$me: Finished configuration testing, now producing output.$ao

files=
objs=
sp=
case $tcfn in
a.exe|conftest.exe)
	buildoutput=$tfn.exe
	add_cppflags -DMKSH_EXE_EXT
	;;
*)
	buildoutput=$tfn
	;;
esac
case $cm in
dragonegg)
	emitbc="-S -flto"
	;;
llvm)
	emitbc="-emit-llvm -c"
	;;
*)
	emitbc=-c
	;;
esac
echo ": # work around NeXTstep bug" >Rebuild.sh
echo set -x >>Rebuild.sh
for file in $SRCS; do
	op=`echo x"$file" | sed 's/^x\(.*\)\.c$/\1./'`
	test -f $file || file=$srcdir/$file
	files="$files$sp$file"
	echo "$CC $CFLAGS $CPPFLAGS $emitbc $file || exit 1" >>Rebuild.sh
	if test $cm = dragonegg; then
		echo "mv ${op}s ${op}ll" >>Rebuild.sh
		echo "llvm-as ${op}ll || exit 1" >>Rebuild.sh
		objs="$objs$sp${op}bc"
	else
		objs="$objs$sp${op}o"
	fi
	sp=' '
done
case $cm in
dragonegg|llvm)
	echo "rm -f $tfn.s" >>Rebuild.sh
	echo "llvm-link -o - $objs | opt $optflags | llc -o $tfn.s" >>Rebuild.sh
	lobjs=$tfn.s
	;;
*)
	lobjs=$objs
	;;
esac
echo tcfn=$buildoutput >>Rebuild.sh
echo "$CC $CFLAGS $LDFLAGS -o \$tcfn $lobjs $LIBS $ccpr" >>Rebuild.sh
echo "test -f \$tcfn || exit 1; $SIZE \$tcfn" >>Rebuild.sh
if test $cm = makefile; then
	extras='string.h'
	cat >Makefrag.inc <<EOF
# Makefile fragment for building MirBSD sleep

PROG=		$buildoutput
MAN=		sleep.1
SRCS=		$SRCS
SRCS_FP=	$files
OBJS_BP=	$objs
INDSRCS=	$extras
NONSRCS_INST=	\$(MAN)
NONSRCS_NOINST=	Build.sh Makefile Rebuild.sh
CC=		$CC
CPPFLAGS=	$CPPFLAGS
CFLAGS=		$CFLAGS
LDFLAGS=	$LDFLAGS
LIBS=		$LIBS

# not BSD make only:
#VPATH=		$srcdir
#all: \$(PROG)
#\$(PROG): \$(OBJS_BP)
#	\$(CC) \$(CFLAGS) \$(LDFLAGS) -o \$@ \$(OBJS_BP) \$(LIBS)
#\$(OBJS_BP): \$(SRCS_FP) \$(NONSRCS)
#.c.o:
#	\$(CC) \$(CFLAGS) \$(CPPFLAGS) -c \$<

# for BSD make only:
#.PATH: $srcdir
#.include <bsd.prog.mk>
EOF
	$e
	$e Generated Makefrag.inc successfully.
	exit 0
fi
if test $cm = combine; then
	objs="-o $buildoutput"
	for file in $SRCS; do
		test -f $file || file=$srcdir/$file
		objs="$objs $file"
	done
	emitbc="-fwhole-program --combine"
	v "$CC $CFLAGS $CPPFLAGS $LDFLAGS $emitbc $objs $LIBS $ccpr"
elif test 1 = $pm; then
	for file in $SRCS; do
		test -f $file || file=$srcdir/$file
		v "$CC $CFLAGS $CPPFLAGS $emitbc $file" &
	done
	wait
else
	for file in $SRCS; do
		test $cm = dragonegg && \
		    op=`echo x"$file" | sed 's/^x\(.*\)\.c$/\1./'`
		test -f $file || file=$srcdir/$file
		v "$CC $CFLAGS $CPPFLAGS $emitbc $file" || exit 1
		if test $cm = dragonegg; then
			v "mv ${op}s ${op}ll"
			v "llvm-as ${op}ll" || exit 1
		fi
	done
fi
case $cm in
dragonegg|llvm)
	rmf $tfn.s
	v "llvm-link -o - $objs | opt $optflags | llc -o $tfn.s"
	;;
esac
tcfn=$buildoutput
test $cm = combine || v "$CC $CFLAGS $LDFLAGS -o $tcfn $lobjs $LIBS $ccpr"
test -f $tcfn || exit 1
test 1 = $r || v "$NROFF -mdoc <'$srcdir/sleep.1' >sleep.cat1" || rmf sleep.cat1
test 0 = $eq && v $SIZE $tcfn
i=install
test -f /usr/ucb/$i && i=/usr/ucb/$i
test 1 = $eq && e=:
$e
$e Installing the executable:
$e "# $i -c -s -o root -g bin -m 555 $tfn /bin/$tfn"
$e
$e Installing the manual:
if test -f sleep.cat1; then
	$e "# $i -c -o root -g bin -m 444 sleep.cat1" \
	    "/usr/share/man/cat1/sleep.0"
	$e or
fi
$e "# $i -c -o root -g bin -m 444 sleep.1 /usr/share/man/man1/"
$e
$e Please also read the fine manual.
exit 0

: <<'EOD'

=== Environment used ===

==== build environment ====
CC				default: cc
CFLAGS				if empty, defaults to -xO2 or +O2
				or -O3 -qstrict or -O2, per compiler
CPPFLAGS			default empty
LDFLAGS				default empty; added before sources
LDSTATIC			set this to '-static'; default unset
LIBS				default empty; added after sources
NOWARN				-Wno-error or similar
NROFF				default: nroff
TARGET_OS			default: $(uname -s || uname)
TARGET_OSREV			[SCO] default: $(uname -r)

===== general format =====
HAVE_STRLEN			ac_test
HAVE_STRING_H			ac_header
HAVE_CAN_FSTACKPROTECTORALL	ac_flags

==== cpp definitions ====
DEBUG				show time actually slept
MKSH_DONT_EMIT_IDSTRING		omit RCS IDs from binary
SMALL				for the MirBSD installer/rescue system

=== generic installation instructions ===

Set CC and possibly CFLAGS, CPPFLAGS, LDFLAGS, LIBS. If cross-compiling,
also set TARGET_OS. To disable tests, set e.g. HAVE_STRLCPY=0; to enable
them, set to a value other than 0 or 1 (e.g. to x).

Normally, the following command is what you want to run, then:
$ sh Build.sh -r 2>&1 | tee log

Install as /bin/sleep; install the manpages, if omitting the -r flag
a catmanpage is made using $NROFF.

EOD
