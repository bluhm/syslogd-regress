# The syslogd is started with reduced file descriptor limits.
# The syslogd config contains more log files than possible.
# The client writes a message to Sys::Syslog native method.
# The syslogd writes it into a file and through a pipe.
# The syslogd passes it via UDP to the loghost.
# The server receives the message on its UDP socket.
# Find the message in client, file, pipe, syslogd, server log.
# Check the error messages and multiple log file content.

use strict;
use warnings;
use Cwd;

my $objdir = getcwd();

our %args = (
    syslogd => {
	conf => join("", map { "*.*\t$objdir/file-$_.log\n" } 0..19),
	rlimit => {
	    RLIMIT_NOFILE => 30,
	},
	loggrep => {
	    qr/receive_fd:/ => 4,
	    qr/X FILE:/ => 1+16,
	    qr/X UNUSED:/ => 4,
	},
    },
    multifile => [
	(map { { loggrep => get_testlog() } } 0..15),
	(map { { loggrep => { qr/./s => 0 } } } 16..19),
    ],
);

1;