# The syslogd binds UDP and TCP socket on localhost.
# The client writes messages into a all localhost sockets.
# The syslogd writes it into a file and through a pipe.
# Find the messages in client, file, syslogd log.
# Check that fstat contains all bound sockets.
# Check that the file log contains all messages.
# Check that client used expected protocol.

use strict;
use warnings;
use Socket;

our %args = (
    client => {
	connect => { domain => AF_UNSPEC, addr => "localhost", port => 514 },
	func => sub {
	    my $self = shift;
	    $self->{redo} = [ "udp", "tcp" ] unless $self->{redo};
	    $self->{connectproto} = shift @{$self->{redo}};
	    undef $self->{redo} unless @{$self->{redo}};
	    write_message($self, "client proto: ", $self->{connectproto});
	    write_log($self);
	},
	loggrep => {
	    qr/connect sock: (127.0.0.1|::1) \d+/ => 2,
	    get_testgrep() => 2,
	},
    },
    syslogd => {
	options => ["-U", "localhost", "-T", "localhost:514"],
	fstat => {
	    qr/ internet6? dgram udp (127.0.0.1|\[::1\]):514$/ => 1,
	    qr/ internet6? stream tcp \w+ (127.0.0.1|\[::1\]):514$/ => 1,
	},
    },
    file => {
	loggrep => {
	    qr/client proto: udp/ => 1,
	    qr/client proto: tcp/ => 1,
	    qr/ localhost /. get_testgrep() => 2,
	}
    },
);

1;
