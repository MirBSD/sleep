/*-
 * Copyright © 2021
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

#define EXTERN
#include "sleep.h"

__RCSID("$MirOS: src/bin/sleep/sleep.c,v 1.7 2021/10/03 20:48:07 tg Exp $");

#ifdef SMALL
static const char ERR[4] = { 'E', 'R', 'R', '\n' };
#define die(...)		do {		\
	write(2, ERR, sizeof(ERR));		\
	_exit(1);				\
} while (/* CONSTCOND */ 0)
#else
static void die(const char *, ...)
    MKSH_A_NORETURN
    MKSH_A_FORMAT(__printf__, 1, 2);
#endif
#ifdef SIGALRM
static void handler(int)
    MKSH_A_NORETURN;
#endif
static unsigned int classify(const char *);
static int dosleep(time_t, unsigned int);

#ifndef SMALL
static void
die(const char *msg, ...)
{
	va_list ap;

	fputs("E: ", stderr);
	va_start(ap, msg);
	vfprintf(stderr, msg, ap);
	va_end(ap);
	putc('\n', stderr);
	exit(1);
}
#endif

#ifdef SIGALRM
static void
handler(int signo MKSH_A_UNUSED)
{
	_exit(0);
}
#endif

/* 0-9; 10=NUL 11=factor 12=period 13=unknown */
static unsigned int
classify(const char *cp)
{
	switch (ord(*cp)) {
	case ord('\0'):
		return (10);
	case ord('0'):
		return (0);
	case ord('1'):
		return (1);
	case ord('2'):
		return (2);
	case ord('3'):
		return (3);
	case ord('4'):
		return (4);
	case ord('5'):
		return (5);
	case ord('6'):
		return (6);
	case ord('7'):
		return (7);
	case ord('8'):
		return (8);
	case ord('9'):
		return (9);
	case ord('.'):
		return (12);
#ifndef SMALL
	case ord('s'):
	case ord('m'):
	case ord('h'):
	case ord('d'):
		if (1[cp] == '\0')
			return (11);
#endif
		/* FALLTHROUGH */
	default:
		return (13);
	}
}

static int
dosleep(time_t s, unsigned int u)
{
	struct timeval tv;

	tv.tv_sec = s;
	tv.tv_usec = u;
	return (select(0, NULL, NULL, NULL, &tv));
}

int
main(int argc, char *argv[])
{
	int argp;
	time_t sS = 0;
	unsigned int sU = 0;
#ifdef notyet_sleepuntil
	struct timeval t0;
#endif
#ifdef DEBUG
	struct timespec ts1, ts2;

	if (clock_gettime(CLOCK_MONOTONIC, &ts1))
		die("clock_gettime: %s", strerror(errno));
#endif

#ifdef notyet_sleepuntil
#if HAVE_GETTIMEOFDAY
	if (gettimeofday(&t0, NULL))
		die("could not get time of day: %s", strerror(errno));
#else
	if (time(&t0.tv_sec) == (time_t)-1)
		die("could not get time: %s", strerror(errno));
	t0.tv_usec = 0;
#endif
#endif

#ifdef SIGALRM
	signal(SIGALRM, handler);
#endif

	argp = 1 + (argc > 1 &&
	    ord(argv[1][0]) == ord('-') &&
	    ord(argv[1][1]) == ord('-') &&
	    !argv[1][2]);
	if (!(argp < argc))
		die("operand is mandatory");
	while (argp < argc) {
		unsigned int i, j, tU = 0;
		time_t tS = 0;
		const char *cp = argv[argp++];
		char argvalid = 0;
#ifndef SMALL
		if (!strcmp(cp, "-V")) {
			fputs("MirBSD sleep(1) " MIRBSD_SLEEP_VERSION "\n",
			    stderr);
			continue;
		}
#endif
 parse_sec:
		if ((i = classify(cp++)) < 10) {
			if (notoktomula(time_t, tS, 10, i)) {
#ifndef SMALL
 overflow:
#endif
				die("argument too large: %s", argv[--argp]);
			}
			tS = (tS * 10) + i;
			argvalid = 1;
			goto parse_sec;
		} else if (i == 10) {
			goto parse_out;
#ifndef SMALL
		} else if (i == 11) {
			goto parse_factor;
#endif
		} else if (i != 12) {
 invopnd:
			die("invalid char '%c' in operand: %s",
			    *--cp, argv[--argp]);
		}
		/* i == 12 */
		j = 100000;
 parse_usec:
		if ((i = classify(cp++)) < 10) {
			if (j) {
				tU += i * j;
				j /= 10;
				/* we continue to parse digits even past µs */
			}
			argvalid = 1;
			goto parse_usec;
#ifndef SMALL
		} else if (i == 11) {
 parse_factor:
			switch (ord(cp[-1])) {
			default: /* ord('s'): */
				goto parse_out;
			case ord('m'):
				i = 60;
				break;
			case ord('h'):
				i = 3600;
				break;
			case ord('d'):
				i = 86400;
				break;
			}
			if (notoktomula(time_t, tS, i, 0))
				goto overflow;
			tS *= i;
			if (tU) {
				/* split tU .mmmuuu to j=mmm tU=uuu and scale */
				j = (tU / 1000U) * i;
				tU = (tU % 1000U) * i;
				/* add s/ms share of tU to j */
				j += tU / 1000U;
				/* add s share of j to tS */
				i = j / 1000U;
				if (notoktoadd(time_t, tS, i))
					goto overflow;
				tS += i;
				/* reconstruct µs share of tU + ms share of j */
				tU = (tU % 1000U) + ((j % 1000U) * 1000U);
			}
#endif
		} else if (i != 10) {
			goto invopnd;
		}
		/* i == 10 or 11-and-past-parsing-factor */
 parse_out:
		if (!argvalid)
			die("operand with no digits: %s", argv[--argp]);
#ifdef TEST
		printf("add %llu.%06u\n", (unsigned long long)tS, tU);
#endif
		sU += tU;
		if (sU > 999999U) {
			if (notoktoadd(time_t, tS, 1))
				goto sumover;
			++tS;
			sU -= 1000000U;
		}
		if (notoktoadd(time_t, sS, tS)) {
 sumover:
			die("argument sum too large at: %s", argv[--argp]);
		}
		sS += tS;
#ifdef TEST
		printf("sum %llu.%06u\n\n", (unsigned long long)sS, sU);
#endif
	}

	while (sS > (21U * 86400U)) {
		if (dosleep(14U * 86400U, 0)) {
 eintr:
			die("sleep: %s", strerror(errno));
		}
		sS -= 14U * 86400U;
	}
	if (dosleep(sS, sU))
		goto eintr;
#ifdef DEBUG
	if (clock_gettime(CLOCK_MONOTONIC, &ts2))
		die("clock_gettime: %s", strerror(errno));
	ts2.tv_sec -= ts1.tv_sec;
	ts2.tv_nsec -= ts1.tv_nsec;
	if (ts2.tv_nsec < 0) {
		ts2.tv_sec--;
		ts2.tv_nsec += 1000000000L;
	}
	printf("%llu.%09lu\n", (unsigned long long)ts2.tv_sec, ts2.tv_nsec);
#endif
	return (0);
}
