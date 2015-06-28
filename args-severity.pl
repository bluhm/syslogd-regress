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
my (@messages, @priorities);
foreach my $fac (qw(local5 local6 local7)) {
    foreach my $sev (qw(notice warning err)) {
	my $msg = "$fac.$sev";
	push @messages, $msg;
	no strict 'refs';
	my $prio = ("Sys::Syslog::LOG_".uc($fac))->() |
	    ("Sys::Syslog::LOG_".uc($sev))->();
	push @priorities, $prio;
    }
}

our %args = (
    client => {
	func => sub {
	    my $self = shift;
	    for (my $i = 0; $i < @messages; $i++) {
		syslog($priorities[$i], $messages[$i]);
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
    server => {
	loggrep => { map { qr/ <$_>/ => 1 } @priorities },
    },
    file => {
	loggrep => { map { qr/: $_$/ => 1 } @messages },
    },
);

1;
