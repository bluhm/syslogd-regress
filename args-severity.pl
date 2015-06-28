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

sub m2l {
    my (%msg, %nomsg);
    @msg{@_} = ();
    @nomsg{@messages} = ();
    delete @nomsg{@_};
    return {
	loggrep => {
	    (map { qr/: $_$/ => 1 } sort keys %msg),
	    (map { qr/: $_$/ => 0 } sort keys %nomsg),
	},
    };
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
*.info		$objdir/file-0.log
*.crit		$objdir/file-1.log
local5.info	$objdir/file-2.log
EOF
    },
    multifile => [
	m2l(@messages),
	m2l(),
	m2l(qw(local5.notice local5.warning local5.err)),
    ],
    server => {
	loggrep => { map { qr/ <$_>/ => 1 } @priorities },
    },
    file => {
	loggrep => { map { qr/: $_$/ => 1 } @messages },
    },
);

1;
