# The syslogd is started with reduced file descriptor limits.
# The syslogd config after SIGHUP contains more log files than possible.
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
    client => {
	func => sub { write_between2logs(shift, sub {
	    my $self = shift;
	    ${$self->{server}}->loggrep("Signal", 8)
		or die ref($self), " no 'Signal' between logs";
	})},
	loggrep => { get_between2loggrep() },
    },
    syslogd => {
	conf => join("", map { "*.*\t$objdir/file-$_.log\n" } 0..19),
	rlimit => {
	    RLIMIT_NOFILE => 30,
	},
	fstat => {},
	ktrace => {},
	loggrep => {
	    qr/syslogd: receive_fd: recvmsg: Message too long/ => 4+2*3,
	    qr/X FILE:/ => 1+16+1+17,
	    qr/X UNUSED:/ => 4+3,
	},
    },
    server => {
	func => sub { read_between2logs(shift, sub {
	    my $self = shift;
	    ${$self->{syslogd}}->kill_syslogd('HUP');
	    ${$self->{syslogd}}->loggrep("syslogd: restarted", 5)
		or die ref($self), " no 'syslogd: restarted' between logs";
	    print STDERR "Signal\n";
	})},
	loggrep => {
	    get_between2loggrep(),
	    qr/Signal/ => 1,
	    qr/Accepted/ => 1,
	},
    },
    multifile => [
	(map { { loggrep => get_testlog() } } 0..16),
	(map { { loggrep => { qr/./s => 0 } } } 17..19),
    ],
);

1;
