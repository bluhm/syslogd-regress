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
foreach (1..4) {
    open(my $fh, '>', "prog$_.log") or die;
}

our %args = (
    client => {
	connect => { domain => AF_UNSPEC, addr => "localhost", port => 514 },
    },
    syslogd => {
	options => ["-u"],
	conf => <<"EOF",
!nonexist
*.*	$objdir/prog1.log
!syslogd-regress
*.*	$objdir/prog2.log
*.*	$objdir/prog4.log
!*
*.*	$objdir/prog4.log
EOF
    },
);

1;
