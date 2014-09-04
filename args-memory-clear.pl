# The client writes a message to Sys::Syslog native method.
# The syslogd writes it into a file and through a pipe.
# Syslogc reads the memory logs.
# The syslogd passes it via UDP to the loghost.
# The server receives the message on its UDP socket.
# Find the message in client, file, pipe, syslogd, server, syslogc log.
# Check that memory buffer has been cleared.

use strict;
use warnings;

our %args = (
    syslogd => {
	memory => 1,
	loggrep => {
	    qr/Accepting control connection/ => 2,
	    qr/ctlcmd 2/ => 1,
	    get_testlog() => 1,
	},
    },
    syslogc => [ {
	options => ["-c", "memory"],
	down => get_downlog(),
    }, {
	options => ["memory"],
	loggrep => { get_testlog() => 0 },
    } ],
);

1;
