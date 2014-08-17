# test with default values
# The client writes a message to the log socket.
# The syslogd writes it into a file and through a pipe.
# The syslogd passes it via udp to the loghost.
# The server receives the message on its udp socket.
# Find the message in client, file, pipe, syslogd, server log.

use strict;
use warnings;

our %args = (
);

1;
