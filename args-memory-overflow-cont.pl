# Syslogc reads the memory logs continously.
# The client writes message to overflow the memory buffer method.
# The syslogd writes it into a file and through a pipe.
# The syslogd passes it via UDP to the loghost.
# The server receives the message on its UDP socket.
# Syslogc reads the memory logs.
# Check that memory buffer has overflow flag.  XXX Does not work yet XXX

use strict;
use warnings;

our %args = (
    client => {
	func => sub {
	    my $self = shift;
	    foreach (1..4) {
		write_message($self, $_ x 1024);
	    }
	    write_shutdown($self);
	},
	nocheck => 1,
    },
    syslogd => {
	memory => 1,
	loggrep => {
	    qr/Accepting control connection/ => 2,
	    qr/ctlcmd 6/ => 1,  # read cont
	    qr/ctlcmd 4/ => 1,  # list
	},
    },
    server => { nocheck => 1 },
    syslogc => [ {
	options => ["-q"],
	loggrep => qr/^memory\* /,
    }, {
	early => 1,
	stop => 1,
	options => ["-f", "memory"],
# XXX	down => qr/ENOBUFS/,
	loggrep => {},
    } ],
    file => { nocheck => 1 },
    pipe => { nocheck => 1 },
);

1;
