# The syslogd listens on 127.0.0.1 TCP socket.
# The client writes a message into a 127.0.0.1 TCP socket.
# The syslogd writes it into a file and through a pipe.
# The syslogd passes it via UDP to the loghost.
# The server receives the message on its UDP socket.
# Find the message in client, file, pipe, syslogd, server log.
# Check that the file log contains the hostname and message.

use strict;
use warnings;
use constant MAXTCP => 20;

our %args = (
    client => {
	connect => { proto => "tcp", addr => "localhost", port => 514 },
    },
    syslogd => {
	options => ["-T", "localhost:514"],
	fstat => {
	    qr/^root .* internet/ => 0,
	    qr/^_syslogd .* internet/ => 3,
	    qr/ internet6? stream tcp \w+ (127.0.0.1|\[::1\]):514$/ => 1,
	},
    },
    file => {
	loggrep => qr/ localhost /. get_testlog(),
    },
);

1;
