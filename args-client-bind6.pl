# Syslog binds UDP socket to ::1.
# The client writes a message to a localhost IPv6 UDP socket.
# The syslogd writes it into a file and through a pipe.
# The syslogd passes it via UDP to the loghost.
# The server receives the message on its UDP socket.
# Find the message in client, file, pipe, syslogd, server log.
# Check that the file log contains the localhost name.
# Check that fstat contains a bound UDP socket.

use strict;
use warnings;

our %args = (
    client => {
	connect => { domain => AF_INET6, addr => "::1", port => 514 },
    },
    syslogd => {
	options => ["-U", "::1"],
	fstat => 1,
    },
    file => {
	loggrep => qr/ localhost /. get_testlog(),
    },
    fstat => {
	loggrep => qr/ internet6 dgram udp \[::1\]:514$/,
    },
);

1;
