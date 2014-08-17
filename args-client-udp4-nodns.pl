# test with default values
# The client writes a message to a localhost IPv4 UDP socket.
# The syslogd writes it into a file and through a pipe.
# The syslogd passes it via udp to the loghost.
# The server receives the message on its udp socket.
# Find the message in client, file, pipe, syslogd, server log.

use strict;
use warnings;

our %args = (
    client => {
	connect => { domain => AF_INET, addr => "127.0.0.1", port => 514 },
    },
    syslogd => {
	options => ["-un"],
    },
    file => {
	loggrep => qr/ 127.0.0.1 /. get_log(),
    },
);

1;
