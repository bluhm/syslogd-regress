/*
 * Copyright (c) 2015 Alexander Bluhm <bluhm@openbsd.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <errno.h>
#include <err.h>
#include <stdio.h>
#include <signal.h>
#include <string.h>
#include <termios.h>
#include <time.h>
#include <unistd.h>
#include <util.h>
#include <utmp.h>

#define LOGFILE	"tty.log"

void timeout(int);

char *tty;

int
main(int argc, char *argv[])
{
	char buf[8192], pty[16];
	struct utmp utmp;
	FILE *log;
	int mfd, sfd;
	ssize_t n;

	if ((log = fopen(LOGFILE, "w")) == NULL)
		err(1, "fopen %s", LOGFILE);
	if (setlinebuf(log) != 0)
		err(1, "setlinebuf");

	if (openpty(&mfd, &sfd, pty, NULL, NULL) == -1)
		err(1, "openpty");
	fprintf(log, "openpty %s\n", pty);
	if ((tty = strrchr(pty, '/')) == NULL)
		errx(1, "tty: %s", pty);
	tty++;

	memset(&utmp, 0, sizeof(utmp));
	strlcpy(utmp.ut_line, tty, sizeof(utmp.ut_line));
	strlcpy(utmp.ut_name, "syslogd", sizeof(utmp.ut_name));
	time(&utmp.ut_time);
	login(&utmp);

	if (signal(SIGALRM, timeout) == SIG_ERR)
		err(1, "signal SIGALRM");
	if (alarm(30) == (unsigned int)-1)
		err(1, "alarm");

	while ((n = read(mfd, buf, sizeof(buf))) > 0) {
		fprintf(log, ">>> ");
		if (fwrite(buf, 1, n, log) != (size_t)n)
			err(1, "fwrite %s", LOGFILE);
		if (buf[n-1] != '\n')
			fprintf(log, "\n");
	}
	if (n < 0)
		err(1, "read %s", pty);

	if (logout(tty) == 0)
		errx(1, "logout %s", tty);

	return (0);
}

void
timeout(int sig)
{
	logout(tty);
	errx(1, "timeout");
}
