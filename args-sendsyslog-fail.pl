# Run client before starting syslogd.
# The client writes a message to Sys::Syslog native method.
# The kernel write an sendsyslog(2) error message to its dmesg log buffer.
# Start syslogd, it reads the message from klog device.
# Find the kernel error message in file, pipe, syslogd, server log.
# Create a ktrace dump of the client and check that sendsyslog(2) has failed.

use strict;
use warnings;

my $kernlog = "/bsd: send message to syslog failed";

our %args = (
    client => {
	early => 1,
	ktrace => 1,
	kdump => {
	    qr/CALL  sendsyslog/ => 2,
	    qr/RET   sendsyslog -1 errno 57 Socket is not connected/ => 2,
	},
    },
    syslogd => {
	loggrep => $kernlog,
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
