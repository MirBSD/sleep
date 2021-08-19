# $MirOS: src/bin/sleep/Makefile,v 1.5 2021/08/19 00:36:48 tg Exp $

.include <bsd.own.mk>

SRCDIR=		${.CURDIR}

PROG=		sleep
.if !make(test-build)
CPPFLAGS+=	\
		-DHAVE_ATTRIBUTE_FORMAT=1 -DHAVE_ATTRIBUTE_NORETURN=1 \
		-DHAVE_ATTRIBUTE_UNUSED=1 -DHAVE_ATTRIBUTE_USED=1 \
		-DHAVE_SYS_TIME_H=1 -DHAVE_TIME_H=1 -DHAVE_BOTH_TIME_H=1 \
		-DHAVE_SYS_SELECT_H=1 -DHAVE_SELECT_TIME_H=1 \
		-DHAVE_SYS_BSDTYPES_H=0 -DHAVE_SYS_PARAM_H=1 \
		-DHAVE_BSTRING_H=0 -DHAVE_STRINGS_H=1 -DHAVE_STRERROR=1
COPTS+=		-fno-asynchronous-unwind-tables -fno-strict-aliasing -Wall
.endif
COPTS+=		-std=c89 -U__STRICT_ANSI__

TEST_BUILD_ENV:=	TARGET_OS= CPP=

test-build: .PHONY
	-rm -rf build-dir
	mkdir -p build-dir
	cd build-dir; env CC=${CC:Q} CFLAGS=${CFLAGS:M*:Q} \
	    CPPFLAGS=${CPPFLAGS:M*:Q} LDFLAGS=${LDFLAGS:M*:Q} \
	    LIBS= NOWARN=-Wno-error ${TEST_BUILD_ENV} /bin/sh \
	    ${SRCDIR}/Build.sh -Q -r

cleandir: clean-extra

clean-extra: .PHONY
	-rm -rf build-dir

.include <bsd.prog.mk>
