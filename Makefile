#	$OpenBSD: Makefile,v 1.6 2014/12/28 14:08:01 bluhm Exp $

# The following ports must be installed for the regression tests:
# p5-IO-Socket-INET6	object interface for AF_INET and AF_INET6 domain sockets
# p5-Socket6		Perl defines relating to AF_INET6 sockets
# p5-IO-Socket-SSL	perl interface to SSL sockets
#
# This package enables additional interoperability tests
# rsyslog		syslog daemon supporting databases, TCP, SSL, RELP
#
# Check wether all required perl packages are installed.  If some
# are missing print a warning and skip the tests, but do not fail.

PERL_REQUIRE !=	perl -Mstrict -Mwarnings -e ' \
    eval { require IO::Socket::INET6 } or print $@; \
    eval { require Socket6 } or print $@; \
    eval { require IO::Socket::SSL } or print $@; \
'
.if ! empty (PERL_REQUIRE)
regress:
	@echo "${PERL_REQUIRE}"
	@echo install these perl packages for additional tests
.endif

# Automatically generate regress targets from test cases in directory.

ARGS !=			cd ${.CURDIR} && ls args-*.pl
.if exists (/usr/local/sbin/rsyslogd)
TARGETS ?=		${ARGS}
.else
TARGETS ?=		${ARGS:Nargs-rsyslog*}
.endif
REGRESS_TARGETS =	${TARGETS:S/^/run-regress-/}
CLEANFILES +=		*.log *.log.? *.pem *.key *.ser *.conf stamp-*
CLEANFILES +=		*.out *.sock ktrace.out *.ktrace *.fstat

.MAIN: all

.if make (regress) || make (all)
.BEGIN:
	@echo
	[ -z "${SUDO}" ] || ${SUDO} true
.END:
	@echo
	${SUDO} /etc/rc.d/syslogd restart
.endif

# Set variables so that make runs with and without obj directory.
# Only do that if necessary to keep visible output short.

.if ${.CURDIR} == ${.OBJDIR}
PERLINC =
PERLPATH =
.else
PERLINC =	-I${.CURDIR}
PERLPATH =	${.CURDIR}/
.endif

# The arg tests take a perl hash with arguments controlling the
# test parameters.  Generally they consist of client, syslogd, server.

.for a in ${ARGS}
run-regress-$a: $a
	@echo '\n======== $@ ========'
	time SUDO=${SUDO} KTRACE=${KTRACE} SYSLOGD=${SYSLOGD} perl ${PERLINC} ${PERLPATH}syslogd.pl ${PERLPATH}$a
.endfor

# create the certificates for TLS

ca-cert.pem:
	openssl req -batch -new -nodes -newkey rsa -keyout ca-key.pem -subj /L=OpenBSD/O=syslogd-regress/OU=ca/CN=root/ -x509 -out ca-cert.pem

server-req.pem:
	openssl req -batch -new -nodes -newkey rsa -keyout server-key.pem -subj /L=OpenBSD/O=syslogd-regress/OU=server/CN=localhost/ -out server-req.pem

server-cert.pem: ca-cert.pem server-req.pem
	openssl x509 -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -req -in server-req.pem -out server-cert.pem

${REGRESS_TARGETS:M*tls*}: server-cert.pem

# make perl syntax check for all args files

.PHONY: syntax libevent

syntax: stamp-syntax

stamp-syntax: ${ARGS}
.for a in ${ARGS}
	@perl -c ${PERLPATH}$a
.endfor
	@date >$@

# run the tests with all variants of libevent backend
libevent:
	cd ${.CURDIR} && EVENT_NOKQUEUE=1 EVENT_NOPOLL=1 ${MAKE} regress
	cd ${.CURDIR} && EVENT_NOKQUEUE=1 EVENT_NOSELECT=1 ${MAKE} regress
	cd ${.CURDIR} && EVENT_NOPOLL=1 EVENT_NOSELECT=1 ${MAKE} regress

.include <bsd.regress.mk>
