# The client writes a message to Sys::Syslog native method.
# The syslogd writes it into a file and through a pipe.
# The syslogd -4 passes it via IPv4 UDP to the loghost.
# The server receives the message on its UDP socket.
# Find the message in client, file, pipe, syslogd, server log.
# Check that the syslogd has no IPv6 socket in fstat output.

use strict;
use warnings;

our %args = (
    syslogd => {
	options => ["-4"],
	fstat => 1,
    },
    fstat => {
	loggrep => {
	    qr/ internet6 / => 0,
	},
    },
);

1;
