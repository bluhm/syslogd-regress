# Test with default values, that is:
# The client writes a message to Sys::Syslog native method.
# The syslogd writes it into a file and through a pipe.
# The syslogd passes it via UDP to the loghost.
# The server receives the message on its UDP socket.
# Find the message in client, file, pipe, syslogd, server log.

use strict;
use warnings;
use Cwd;

my $objdir = getcwd();

our %args = (
    client => {
	connect => { domain => AF_UNSPEC, addr => "localhost", port => 514 },
    },
    syslogd => {
	options => ["-u"],
	conf => <<"EOF",
!nonexist
*.*	$objdir/file-0.log
!syslogd
*.*	$objdir/file-1.log
*.*	$objdir/file-2.log
!*
*.*	$objdir/file-3.log
EOF
    },
    multifile => [
	{ loggrep => { get_testlog() => 0 } },
	{ loggrep => { get_testlog() => 1 } },
	{ loggrep => { get_testlog() => 1 } },
	{ loggrep => { get_testlog() => 1 } },
    ],
);

1;
