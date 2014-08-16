#	$OpenBSD$

# The following ports must be installed for the regression tests:
# p5-IO-Socket-INET6	object interface for AF_INET and AF_INET6 domain sockets
# p5-Socket6		Perl defines relating to AF_INET6 sockets
# p5-IO-Socket-SSL	perl interface to SSL sockets
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

# Fill out these variables if you want to test syslogd with
# the syslogd process running on a remote machine.  You have to specify
# a local and remote ip address for the test connections.  To control
# the remote machine you need a hostname for ssh to log in.  All the
# test files must be in the same directory local and remote.
#
# Run make check-setup to see if you got the setup correct.

LOCAL_ADDR ?=
REMOTE_ADDR ?=
LOCAL_ADDR6 ?=
REMOTE_ADDR6 ?=
REMOTE_SSH ?=

# Automatically generate regress targets from test cases in directory.

ARGS !=			cd ${.CURDIR} && ls args-*.pl
TARGETS ?=		${ARGS}
REGRESS_TARGETS =	${TARGETS:S/^/run-regress-/}
CLEANFILES +=		*.log *.pem *.crt *.key syslog.conf ktrace.out stamp-*

.MAIN: all

.if empty (REMOTE_SSH)
.if make (regress) || make (all)
.BEGIN:
	@echo
	[ -z "${SUDO}" ] || ${SUDO} true
.END:
	@echo
	${SUDO} /etc/rc.d/syslogd restart
.endif
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
.if empty (REMOTE_SSH)
	time SUDO=${SUDO} KTRACE=${KTRACE} SYSLOGD=${SYSLOGD} perl ${PERLINC} ${PERLPATH}syslogd.pl ${PERLPATH}$a
.else
	ssh -t ${REMOTE_SSH} ${SUDO} true
	time SUDO=${SUDO} KTRACE=${KTRACE} SYSLOGD=${SYSLOGD} perl ${PERLINC} ${PERLPATH}remote.pl ${LOCAL_ADDR} ${REMOTE_ADDR} ${REMOTE_SSH} ${PERLPATH}$a
.endif
.endfor

# create the certificates for SSL

.for ip in ${REMOTE_ADDR} 127.0.0.1
${ip}.crt:
	openssl req -batch -new -nodes -newkey rsa -keyout ${ip}.key -subj /CN=${ip}/ -x509 -out $@
.if empty (REMOTE_SSH)
	${SUDO} cp 127.0.0.1.crt /etc/ssl/
	${SUDO} cp 127.0.0.1.key /etc/ssl/private/
.else
	scp ${REMOTE_ADDR}.crt root@${REMOTE_SSH}:/etc/ssl/
	scp ${REMOTE_ADDR}.key root@${REMOTE_SSH}:/etc/ssl/private/
.endif
.endfor

server-cert.pem:
	openssl req -batch -new -nodes -newkey rsa -keyout server-key.pem -subj /CN=localhost/ -x509 -out $@

${REGRESS_TARGETS:M*ssl*} ${REGRESS_TARGETS:M*https*}: server-cert.pem
.if empty (REMOTE_SSH)
${REGRESS_TARGETS:M*ssl*} ${REGRESS_TARGETS:M*https*}: 127.0.0.1.crt
.else
${REGRESS_TARGETS:M*ssl*} ${REGRESS_TARGETS:M*https*}: ${REMOTE_ADDR}.crt
.endif

# make perl syntax check for all args files

.PHONY: syntax

syntax: stamp-syntax

stamp-syntax: ${ARGS}
.for a in ${ARGS}
	@perl -c ${PERLPATH}$a
.endfor
	@date >$@

# Check wether the address, route and remote setup is correct
check-setup:
	@echo '\n======== $@ ========'
	ping -n -c 1 ${LOCAL_ADDR}
	ping -n -c 1 ${REMOTE_ADDR}
	ping6 -n -c 1 ${LOCAL_ADDR6}
	ping6 -n -c 1 ${REMOTE_ADDR6}
	ssh ${REMOTE_SSH} perl -MIO::Socket::INET6 -MSocket6 -e 1

.include <bsd.regress.mk>
