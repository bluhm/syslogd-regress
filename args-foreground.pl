# Start syslogd in foreground mode.
# The client writes a message to Sys::Syslog native method.
# The syslogd writes it into a file and through a pipe.
# The syslogd passes it via UDP to the loghost.
# The server receives the message on its UDP socket.
# Find the message in client, file, pipe, syslogd, server log.
# Check ktrace for setting the correct uid and gid.
# Check fstat that the parent process has no inet sockets.

use strict;
use warnings;

our %args = (
    syslogd => {
	foreground => 1,
	ktrace => 1,
	fstat => 1,
    }
);

1;
