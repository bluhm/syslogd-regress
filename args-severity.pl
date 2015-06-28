# The client sends messages with different facility and priority.
# The syslogd writes into multiple files depending on severity.
# The syslogd writes it into a file and through a pipe.
# The syslogd passes it via UDP to the loghost.
# The server receives the message on its UDP socket.
# Find the message in client, file, pipe, syslogd, server log.
# Check that the messages appears in the correct log files.

use strict;
use warnings;
use Cwd;
use Sys::Syslog;

my $objdir = getcwd();

our %args = (
    client => {
	func => sub {
	    my $self = shift;
	    foreach my $fac (qw(local5 local6 local7)) {
		foreach my $sev (qw(notice warning err)) {
		    no strict 'refs';
		    my $facility = ("Sys::Syslog::LOG_".uc($fac))->();
		    my $severity = ("Sys::Syslog::LOG_".uc($sev))->();
		    syslog($facility|$severity, "$fac.$sev");
		}
	    }
	    write_log($self);
	},
    },
    syslogd => {
	conf => <<"EOF",
*.*	$objdir/file-0.log
*.*	$objdir/file-1.log
*.*	$objdir/file-2.log
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
