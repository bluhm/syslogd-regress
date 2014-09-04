# The client writes a message to Sys::Syslog native method.
# The syslogd writes it into a file and through a pipe.
# Syslogc reads the memory logs.
# The syslogd passes it via UDP to the loghost.
# The server receives the message on its UDP socket.
# Find the message in client, file, pipe, syslogd, server, syslogc log.

use strict;
use warnings;

our %args = (
    syslogd => {
	memory => 1,
	loggrep => {
	    qr/Accepting control connection/ => 1,
	    qr/ctlcmd 1/ => 1,
	    get_testlog() => 1,
	},
    },
    syslogc => {
	options => ["memory"],
	down => get_downlog(),
    },
);

1;
