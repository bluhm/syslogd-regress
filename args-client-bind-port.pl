# Syslog binds UDP socket to localhost and port.
# The client writes a message to Sys::Syslog UDP method.
# The syslogd writes it into a file and through a pipe.
# The syslogd passes it via UDP to the loghost.
# The server receives the message on its UDP socket.
# Find the message in client, file, pipe, syslogd, server log.
# Check that the file log contains the localhost name.
# Check that fstat contains a bound UDP socket.

use strict;
use warnings;
require 'funcs.pl';


my $port = find_ports();

our %args = (
    client => {
	connect => { domain => AF_UNSPEC, addr => "localhost", port => $port },
	loggrep => {
	    qr/connect sock: (127.0.0.1|::1) \d+/ => 1,
	    get_testlog() => 1,
	},
    },
    syslogd => {
	options => ["-U", "localhost:$port"],
	fstat => qr/ internet6? dgram udp (127.0.0.1|\[::1\]):$port$/,
    },
);

1;
