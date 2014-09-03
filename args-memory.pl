# The client writes a message to Sys::Syslog native method.
# The syslogd writes it into a file and through a pipe.
# Syslogc queries the memory logs.
# The syslogd passes it via UDP to the loghost.
# The server receives the message on its UDP socket.
# Find the message in client, file, pipe, syslogd, server log.

use strict;
use warnings;

our %args = (
    syslogd => {
	memory => 1,
	loggrep => {
	    qr/Accepting control connection/ => 1,
	    qr/ctlcmd 4/ => 1,
	    get_log() => 1,
	},
    },
    syslogc => {
	options => ["-q"],
    },
);

1;
