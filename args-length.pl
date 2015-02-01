# The client writes long messages to UDP socket.
# The syslogd writes it into a file and through a pipe.
# The syslogd passes it via UDP to the loghost.
# The server receives the message on its UDP socket.
# Find the message in client, file, pipe, syslogd, server log.
# Check that lines in file have 8192 bytes message length after the header.
# Check that lines in server have 8192 bytes line length.

use strict;
use warnings;
use Socket;

my $msg = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

our %args = (
    client => {
	connect => { domain => AF_UNSPEC, addr => "localhost", port => 514 },
	func => \&write_length,
	lengths => [ 8190..8193,9000 ],
    },
    syslogd => {
	options => ["-u"],
	loggrep => {
	    $msg => 5,
	}
    },
    server => {
	# >>> <13>Jan 31 00:10:11 0123456789ABC...lmn
	loggrep => {
	    $msg => 5,
	    qr/^>>> .{8192}$/ => 5,
	},
    },
    file => {
	# Jan 31 00:12:39 localhost 0123456789ABC...567
	loggrep => {
	    $msg => 5,
	    qr/^.{8216}$/ => 1,
	    qr/^.{8217}$/ => 1,
	    qr/^.{8218}$/ => 3,
	},
    },
);

1;
