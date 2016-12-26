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
	connectproto => "none",
	func => sub {
	    my $self = shift;
	    $self->{redo} ||= [
		{
		    proto  => "udp",
		    domain => AF_INET,
		    addr   => "127.0.0.1",
		    port   => 514
		},
		{
		    proto  => "tcp",
		    domain => AF_INET6,
		    addr   => "::1",
		    port   => 514
		},
	    ];
	    write_message($self, "client proto: ". $self->{connectproto});
	    if (my $connect = shift @{$self->{redo}}) {
		$self->{connectproto}  = $connect->{proto};
		$self->{connectdomain} = $connect->{domain};
		$self->{connectaddr}   = $connect->{addr};
		$self->{connectport}   = $connect->{port};
	    } else {
		write_log($self);
		undef $self->{redo};
	    }
	},
	loggrep => {
	    qr/connect sock: (127.0.0.1|::1) \d+/ => 2,
	    get_testgrep() => 1,
	},
    },
    syslogd => {
	options => ["-U", "127.0.0.1", "-T", "[::1]:514"],
	fstat => {
	    qr/ internet6? dgram udp (127.0.0.1|\[::1\]):514$/ => 1,
	    qr/ internet6? stream tcp \w+ (127.0.0.1|\[::1\]):514$/ => 1,
	},
    },
    file => {
	loggrep => {
	    qr/client proto: udp/ => 1,
	    qr/client proto: tcp/ => 1,
	    qr/ localhost /. get_testgrep() => 1,
	}
    },
);

1;
