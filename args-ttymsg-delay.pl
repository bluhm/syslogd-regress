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
	func => sub { write_between2logs(shift, sub {
	    my $self = shift;
	    write_lines($self, 300, 1024);
	})},
    },
    syslogd => {
	loggrep => {
	    qr/ttymsg delayed write/ => '>=1',
	},
    },
    tty => {
	loggrep => {
	    get_between2loggrep(),
	},
    },
);

1;
