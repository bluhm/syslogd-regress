# The client writes message to overflow the memory buffer method.
# The syslogd writes it into a file and through a pipe.
# The syslogd passes it via UDP to the loghost.
# The server receives the message on its UDP socket.
# Syslogc reads the memory logs.
# Find the message in client, file, pipe, syslogd, server, syslogc log.
# Check that memory buffer has not been cleared.

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
	    qr/Accepting control connection/ => 5,
	    qr/ctlcmd 1/ => 1,  # read
	    qr/ctlcmd 2/ => 1,  # read clear
	    qr/ctlcmd 4/ => 3,  # list
	},
    },
    server => { nocheck => 1 },
    syslogc => [ {
	options => ["-q"],
	loggrep => qr/^memory\* /,
    }, {
	options => ["memory"],
	down => get_downlog(),
	loggrep => {},
    }, {
	options => ["-q"],
	loggrep => qr/^memory\* /,
    }, {
	options => ["-c", "memory"],
	down => get_downlog(),
	loggrep => {},
    }, {
	options => ["-q"],
	loggrep => qr/^memory /,
    } ],
    file => { nocheck => 1 },
    pipe => { nocheck => 1 },
);

1;
