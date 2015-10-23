# The client writes messages to Sys::Syslog native method.
# The syslogd writes it into a file and through a pipe and to tty.
# The tty reader blocks the read for a while.
# The syslogd passes it via UDP to the loghost.
# The server receives the message on its UDP socket.
# Find the message in client, file, pipe, tty, syslogd, server log.
# Check that syslogd has logged that the tty blocked.

use strict;
use warnings;
use Sys::Syslog qw(:macros);

our %args = (
    client => {
	func => sub {
	    my $self = shift;
	    write_lines($self, 3, 1024);
	    write_log($self);
	},
    },
    syslogd => {
	loggrep => {
	    qr/ttymsg delayed write/ => '>=1',
	},
    },
);

1;
