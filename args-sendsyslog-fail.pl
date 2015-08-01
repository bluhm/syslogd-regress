# Run client before starting syslogd.
# The client writes a message to Sys::Syslog native method.
# The kernel writes a sendsyslog(2) error message to its dmesg log buffer.
# Start syslogd, it reads the message from klog device.
# Client writes messages until the kernel rate limit is exceeded.
# Find the kernel error message in file, pipe, syslogd, server log.
# Create a ktrace dump of the client and check that sendsyslog(2) has failed.

use strict;
use warnings;

my $kernlog = "/bsd: send message to syslog failed";

our %args = (
    client => {
	early => 1,
	ktrace => {
	    qr/CALL  sendsyslog/ => '>=2',
	    qr/RET   sendsyslog -1 errno 57 Socket is not connected/ => '>=2',
	},
    },
    syslogd => {
	loggrep => {
	    $kernlog => 2,
	    qr/$kernlog \d+ more times/ => 1,
	},
    },
    server => {
	func => sub {
	    my $self = shift;
	    read_message($self, $kernlog, @_);
	},
	loggrep => $kernlog,
    },
    file => { loggrep => $kernlog },
    pipe => { loggrep => $kernlog },
);

1;
