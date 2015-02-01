# The client writes a message to Sys::Syslog unix method.
# The syslogd writes it into a file and through a pipe.
# The syslogd passes it via UDP to the loghost.
# The server receives the message on its UDP socket.
# Find the message in client, file, pipe, syslogd, server log.
# Check that lines in file have 8192 bytes message length after the header.

use strict;
use warnings;
use Socket;

my $msg = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

our %args = (
    client => {
	logsock => { type => "unix" },
	func => \&write_length,
	lengths => [ 8190..8193,9000 ],
    },
    syslogd => {
	loggrep => {
	    $msg => 5,
	}
    },
    file => {
	# Jan 31 00:12:39 localhost 0123456789ABC...567
	loggrep => {
	    $msg => 5,
	    qr/^.{25} .{8190}$/ => 1,
	    qr/^.{25} .{8191}$/ => 1,
	    qr/^.{25} .{8192}$/ => 3,
	},
    },
);

1;
