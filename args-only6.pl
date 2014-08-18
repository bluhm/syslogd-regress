# The client writes a message to Sys::Syslog native method.
# The syslogd writes it into a file and through a pipe.
# The syslogd -6 passes it via IPv6 UDP to the loghost.
# The server receives the message on its UDP socket.
# Find the message in client, file, pipe, syslogd, server log.
# Check that the syslogd has no IPv4 socket in fstat output.

use strict;
use warnings;

our %args = (
    syslogd => {
	fstat => 1,
	loghost => '@[::1]:$connectport',
	options => ["-6"],
    },
    server => {
	listen => { domain => AF_INET6, addr => "::1" },
    },
    fstat => {
	loggrep => {
	    qr/ internet / => 0,
	},
    },
);

1;
