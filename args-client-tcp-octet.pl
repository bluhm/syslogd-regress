# The syslogd listens on 127.0.0.1 TCP socket.
# The client writes a message to Sys::Syslog TCP method.
# The syslogd writes it into a file and through a pipe.
# The syslogd passes it via UDP to the loghost.
# The server receives the message on its UDP socket.
# Find the message in client, file, pipe, syslogd, server log.
# Check that the file log contains the hostname and message.

use strict;
use warnings;

our %args = (
    client => {
	connect => { domain => AF_INET, proto => "tcp", addr => "127.0.0.1",
	    port => 514 },
	func => sub {
	    my $self = shift;
	    print "0 1 a2 bc3 de\n3 fg\0003 hi 4 jk\n\n1 l0 1 m2 n ";
	    write_log($self);
	},
    },
    syslogd => {
	options => ["-T", "127.0.0.1:514"],
	loggrep => {
	},
    },
    file => {
	loggrep => {
	    get_testgrep() => 1,
	},
    },
);

1;
