# The client writes long messages to UDP socket.
# The syslogd writes it into a file and through a pipe.
# The syslogd passes it via UDP to the loghost.
# The server receives the message on its UDP socket.
# Find the message in client, file, pipe, syslogd, server log.
# Check that lines with visual encoding at the end are truncated.

use strict;
use warnings;
use Socket;

my $msg = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

our %args = (
    client => {
	connect => { domain => AF_UNSPEC, addr => "localhost", port => 514 },
	func => \&write_length,
	lengths => [ 8186..8195,9000 ],
	tail => "foo\200",
    },
    syslogd => {
	options => ["-u"],
	loggrep => {
	    $msg => 11,
	}
    },
    server => {
	# >>> <13>Jan 31 00:10:11 0123456789ABC...lmn
	loggrep => {
	    $msg => 11,
	    qr/^>>> .{8192}$/ => 11,
	},
    },
    file => {
	# Jan 31 00:12:39 localhost 0123456789ABC...567
	loggrep => {
	    $msg => 11,
	    qr/^.{8208}foo\\M\^\@$/ => 1,
	    qr/^.{8209}foo\\M\^\@$/ => 1,
	    qr/^.{8210}foo\\M\^\@$/ => 1,
	    qr/^.{8211}foo\\M\^\@$/ => 1,
	    qr/^.{8212}foo\\M\^$/ => 1,
	    qr/^.{8213}foo\\M$/ => 1,
	    qr/^.{8214}foo\\$/ => 1,
	    qr/^.{8215}foo$/ => 1,
	    qr/^.{8216}fo$/ => 1,
	    qr/^.{8217}f$/ => 1,
	    qr/^.{8218}$/ => 8,
	},
    },
);

1;
