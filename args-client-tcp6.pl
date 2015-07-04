# The syslogd listens on ::1 TCP socket.
# The client writes a message into a ::1 TCP socket.
# The syslogd writes it into a file and through a pipe.
# The syslogd passes it via UDP to the loghost.
# The server receives the message on its UDP socket.
# Find the message in client, file, pipe, syslogd, server log.
# Check that the file log contains the hostname and message.

use strict;
use warnings;

our %args = (
    client => {
	connect => { domain => AF_INET6, proto => "tcp", addr => "::1",
	    port => 514 },
	func => sub {
	    my $self = shift;
	    write_message($self, get_testlog());
	    print "\n";
	    write_shutdown($self);
	},
	loggrep => {
	    qr/connect sock: ::1 \d+/ => 1,
	    get_testlog() => 1,
	},
    },
    syslogd => {
	options => ["-T", "[::1]:514"],
	fstat => {
	    qr/^root .* internet/ => 0,
	    qr/^_syslogd .* internet/ => 3,
	    qr/ internet6 stream tcp \w+ \[::1\]:514$/ => 1,
	},
    },
    file => {
	loggrep => qr/ localhost /. get_testlog(),
    },
);

1;
