# The client writes a message to Sys::Syslog native method.
# The syslogd writes it into a file and through a pipe.
# XXX
# The syslogd passes it via UDP to the loghost.
# The server receives the message on its UDP socket.
# Find the message in client, file, pipe, syslogd, server log.

use strict;
use warnings;

our %args = (
    syslogd => {
	memory => 1,
	loggrep => {
	    get_log() => 1,
	},
    },
);

1;
