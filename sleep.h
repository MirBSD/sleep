/*-
 * Copyright © 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010,
 *	       2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018,
 *	       2019, 2020, 2021
 *      mirabilos <m@mirbsd.org>
 *
 * Provided that these terms and disclaimer and all copyright notices
 * are retained or reproduced in an accompanying document, permission
 * is granted to deal in this work without restriction, including un‐
 * limited rights to use, publicly perform, distribute, sell, modify,
 * merge, give away, or sublicence.
 *
 * This work is provided “AS IS” and WITHOUT WARRANTY of any kind, to
 * the utmost extent permitted by applicable law, neither express nor
 * implied; without malicious intent or gross negligence. In no event
 * may a licensor, author or contributor be held liable for indirect,
 * direct, other damage, loss, or other issues arising in any way out
 * of dealing in the work, even if advised of the possibility of such
 * damage or existence of a defect, except proven that it results out
 * of said person’s immediate fault when using the work as intended.
 */

#if HAVE_SYS_PARAM_H
#include <sys/param.h>
#endif
#include <sys/types.h>
#if HAVE_BOTH_TIME_H
#include <sys/time.h>
#include <time.h>
#elif HAVE_SYS_TIME_H
#include <sys/time.h>
#elif HAVE_TIME_H
#include <time.h>
#endif
#if HAVE_SYS_BSDTYPES_H
#include <sys/bsdtypes.h>
#endif
#if HAVE_SYS_SELECT_H
#include <sys/select.h>
#endif
#if HAVE_BSTRING_H
#include <bstring.h>
#endif
#include <errno.h>
#include <signal.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#if HAVE_STRINGS_H
#include <strings.h>
#endif
#include <unistd.h>

/* from mksh */

#if HAVE_ATTRIBUTE_FORMAT
#define MKSH_A_FORMAT(x,y,z)	__attribute__((__format__(x, y, z)))
#else
#define MKSH_A_FORMAT(x,y,z)	/* nothing */
#endif
#if HAVE_ATTRIBUTE_NORETURN
#define MKSH_A_NORETURN		__attribute__((__noreturn__))
#else
#define MKSH_A_NORETURN		/* nothing */
#endif
#if HAVE_ATTRIBUTE_UNUSED
#define MKSH_A_UNUSED		__attribute__((__unused__))
#else
#define MKSH_A_UNUSED		/* nothing */
#endif

#if defined(MirBSD) && (MirBSD >= 0x09A1) && \
    defined(__ELF__) && defined(__GNUC__) && \
    !defined(__llvm__) && !defined(__NWCC__)
/*
 * We got usable __IDSTRING __COPYRIGHT __RCSID __SCCSID macros
 * which work for all cases; no need to redefine them using the
 * "portable" macros from below when we might have the "better"
 * gcc+ELF specific macros or other system dependent ones.
 */
#else
#undef __IDSTRING
#undef __IDSTRING_CONCAT
#undef __IDSTRING_EXPAND
#undef __COPYRIGHT
#undef __RCSID
#undef __SCCSID
#define __IDSTRING_CONCAT(l,p)		__LINTED__ ## l ## _ ## p
#define __IDSTRING_EXPAND(l,p)		__IDSTRING_CONCAT(l,p)
#ifdef MKSH_DONT_EMIT_IDSTRING
#define __IDSTRING(prefix,string)	/* nothing */
#elif defined(__ELF__) && defined(__GNUC__) && \
    !(defined(__GNUC__) && defined(__mips16) && (__GNUC__ >= 8)) && \
    !defined(__llvm__) && !defined(__NWCC__) && !defined(NO_ASM)
#define __IDSTRING(prefix,string)				\
	__asm__(".section .comment"				\
	"\n	.ascii	\"@(\"\"#)" #prefix ": \""		\
	"\n	.asciz	\"" string "\""				\
	"\n	.previous")
#else
#define __IDSTRING(prefix,string)				\
	static const char __IDSTRING_EXPAND(__LINE__,prefix) []	\
	    MKSH_A_USED = "@(""#)" #prefix ": " string
#endif
#define __COPYRIGHT(x)		__IDSTRING(copyright,x)
#define __RCSID(x)		__IDSTRING(rcsid,x)
#define __SCCSID(x)		__IDSTRING(sccsid,x)
#endif

#ifdef EXTERN
__RCSID("$MirOS: src/bin/sleep/sleep.h,v 1.2 2021/01/23 06:12:47 tg Exp $");
#endif

#define ord(c)			((unsigned int)(unsigned char)(c))

/* maximum value of a type, no matter which signedness */
#define type_max(t)		(((t)(-1) < (t)0) ? \
	(((t)((t)1 << (sizeof(t)*CHAR_BIT - 2)) - (t)1) * (t)2 + (t)1) : \
	((t)~(t)0))

/* check for overflow */
#define notoktomula(t,val,c,a)	(((val) != 0) && ((c) != 0) && \
	(((type_max(t) - (t)(a)) / (t)(c)) < (t)(val)))
#define notoktoadd(t,val,c)	((t)(val) > (type_max(t) - (t)(c)))

/* missing functions */
#if !HAVE_STRERROR
#define strerror(e)		"no strerror to decode errno"
#endif
