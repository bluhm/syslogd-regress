# The client kills syslogd.
# The client writes a message with sendsyslog2 LOG_CONS flag.
# Find the message in console log.
# Create a ktrace dump of the client and check for sendsyslog2.
# Check that no syslog priority or dropped message is logged to console.

use strict;
use warnings;
use Errno ':POSIX';
use Sys::Syslog 'LOG_CONS';

my $errno = ENOTCONN;
my $message = "<123>". get_testlog();

our %args = (
    client => {
	func => sub {
	    my $self = shift;
	    ${$self->{syslogd}}->kill_syslogd('TERM');
	    ${$self->{syslogd}}->down();
	    sendsyslog2($message, LOG_CONS)
		and die ref($self), " sendsyslog2 succeeded";
	    write_shutdown($self);
	},
	ktrace => {
	    qr/CALL  sendsyslog2\(/ => 2,
	    qr/GIO   fd -1 wrote /.length($message).qr/ bytes/ => 1,
	    qr/RET   sendsyslog2 -1 errno $errno / => 2,
	},
	loggrep => {},
    },
    syslogd => {
	conffile => "/dev/null",
	loggrep => {},
    },
    server => { noserver => 1 },
    file => { nocheck => 1 },
    pipe => { nocheck => 1 },
    user => { nocheck => 1 },
    console => {
	loggrep => {
	    get_testgrep() => 1,
	    qr/<\d+>/ => 0,
	    qr/dropped \d+ message/ => 0,
	},
    },
);

1;
