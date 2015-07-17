# The syslogd listens on 127.0.0.1 TCP socket.
# The client writes octet counting and non transpatent framing in chunks.
# The syslogd writes it into a file and through a pipe.
# The syslogd passes it via UDP to the loghost.
# The server receives the message on its UDP socket.
# Find the message in client, file, pipe, syslogd, server log.
# Check that the file log contains all the messages.

use strict;
use warnings;

our %args = (
    client => {
	connect => { domain => AF_INET, proto => "tcp", addr => "127.0.0.1",
	    port => 514 },
	func => sub {
	    my $self = shift;
	    print "2 ab";
	    print "2 c";
	    print "def\n";
	    print "g";
	    print "h\n2 ij";
	    write_log($self);
	},
    },
    syslogd => {
	options => ["-T", "127.0.0.1:514"],
    },
    file => {
	loggrep => {
	    qr/localhost ab$/ => 1,
	    qr/localhost cd$/ => 1,
	    qr/localhost ef$/ => 1,
	    qr/localhost gh$/ => 1,
	    qr/localhost ij$/ => 1,
	    get_testgrep() => 1,
	},
    },
);

1;
