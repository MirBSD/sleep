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

__RCSID("$MirOS: src/bin/sleep/sleep.c,v 1.4 2021/01/23 03:36:59 tg Exp $");

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
static unsigned int classify(unsigned int);
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
classify(unsigned int ch)
{
	switch (ch) {
	case ord('\0'):
		return (10);
	case ord('.'):
		return (12);
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
	case ord('s'):
	case ord('m'):
	case ord('h'):
	case ord('d'):
		return (11);
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

	argp = 1;
	if (argp < argc && !strcmp(argv[argp], "--"))
		++argp;
	if (!(argp < argc))
		die("operand is mandatory");

	while (argp < argc) {
		unsigned int i, j, tU = 0;
		time_t tS = 0;
		const char *cp = argv[argp];
		char argvalid = 0;
 parse_sec:
		if ((i = classify(ord(*cp))) > 9) switch (i) {
		case 10:
			goto parse_out;
		case 11:
			goto parse_factor;
		case 12:
			++cp;
			j = 100000;
			goto parse_usec;
		default:
			die("invalid char '%c' in operand: %s",
			    *cp, argv[argp]);
		}
		argvalid = 1;
		if (notoktomul(time_t, tS, 10)) {
 overflow:
			die("argument too large: %s", argv[argp]);
		}
		tS *= 10;
		if (notoktoadd(time_t, tS, i))
			goto overflow;
		tS += i;
		++cp;
		goto parse_sec;
 parse_usec:
		if ((i = classify(ord(*cp))) > 9) switch (i) {
		case 10:
			goto parse_out;
		case 11:
			goto parse_factor;
		default:
			die("invalid char '%c' in operand: %s",
			    *cp, argv[argp]);
		}
		argvalid = 1;
		if (j) {
			tU += i * j;
			j /= 10;
			/* we continue to parse digits even past µs */
		}
		++cp;
		goto parse_usec;
 parse_factor:
		if (cp[1])
			die("operand continues past %c suffix: %s",
			    *cp, argv[argp]);
		switch (ord(*cp)) {
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
		if (notoktomul(time_t, tS, i))
			goto overflow;
		tS *= i;
		if (!tU)
			goto parse_out;
		/* split tU .mmmuuu to j=mmm tU=uuu and scale */
		j = (tU / 1000U) * i;
		tU = (tU % 1000U) * i;
		/* add s/ms share of tU to j */
		j += tU / 1000U;
		/* add s share of j to tS */
		if (notoktoadd(time_t, tS, j / 1000U))
			goto overflow;
		tS += j / 1000U;
		/* reconstruct µs share of tU + ms share of j */
		tU = (tU % 1000U) + ((j % 1000U) * 1000U);
 parse_out:
		if (!argvalid)
			die("operand with no digits: %s", argv[argp]);
#ifdef TEST
		printf("add %llu.%06u\n", (unsigned long long)tS, tU);
#endif
		sU += tU;
		while (sU > 999999U) {
			if (notoktoadd(time_t, tS, 1))
				goto sumover;
			++tS;
			sU -= 1000000U;
		}
		if (notoktoadd(time_t, sS, tS)) {
 sumover:
			die("argument sum too large at: %s", argv[argp]);
		}
		sS += tS;
#ifdef TEST
		printf("sum %llu.%06u\n\n", (unsigned long long)sS, sU);
#endif
		++argp;
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
	timespecsub(&ts2, &ts1, &ts1);
	printf("%llu.%09lu\n", (unsigned long long)ts1.tv_sec, ts1.tv_nsec);
#endif
	return (0);
}