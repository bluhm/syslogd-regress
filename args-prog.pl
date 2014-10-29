# Test with default values, that is:
# The client writes a message to Sys::Syslog native method.
# The syslogd writes it into a file and through a pipe.
# The syslogd passes it via UDP to the loghost.
# The server receives the message on its UDP socket.
# Find the message in client, file, pipe, syslogd, server log.

use strict;
use warnings;
use Cwd;

my $foolog = getcwd()."/foo.log";
my $barlog = getcwd()."/bar.log";
{
    my $fh;
    open($fh, '>', $foolog) or die "Create $foolog failed: $!";
    open($fh, '>', $barlog) or die "Create $barlog failed: $!";
}

our %args = (
    syslogd => {
	conf => <<"EOF",
!myprog
*.*	foo.log
!!myprog
*.*	bar.log
EOF
    },
);

1;
