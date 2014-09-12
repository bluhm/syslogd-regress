# Syslogc reads the memory logs continously.
# The client writes message to overflow the memory buffer method.
# The syslogd writes it into a file and through a pipe.
# The syslogd passes it via UDP to the loghost.
# The server receives the message on its UDP socket.
# Syslogc reads the memory logs.
# Check that memory buffer has overflow flag.  XXX Does not work yet XXX

use strict;
use warnings;
use Time::HiRes 'sleep';

our %args = (
    client => {
	func => sub {
	    my $self = shift;
	    foreach (1..500) {
		write_message($self, $_ x 1024);
		sleep .01;
	    }
	    write_log($self);
	},
    },
    syslogd => {
	memory => 1,
	loggrep => {
	    qr/Accepting control connection/ => 1,
	    qr/ctlcmd 6/ => 1,  # read cont
	},
    },
    syslogc => [ {
	early => 1,
	stop => 1,
	options => ["-f", "memory"],
	down => qr/Lines were dropped!/,
	loggrep => {},
    } ],
);

1;
