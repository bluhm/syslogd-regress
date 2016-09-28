# The client writes a message to Sys::Syslog native method.
# The syslogd writes it into a file and through a pipe and to tty.
# The syslogd passes it via UDP to the loghost.
# The server receives the message on its UDP socket.
# Find the message in client, file, pipe, console, user, syslogd, server log.

use strict;
use warnings;
use Sys::Hostname;

(my $host = hostname()) =~ s/\..*//;

# 2016-09-28T15:38:09Z
my $iso = qr/20\d\d-\d\d-\d\dT\d\d:\d\d:\d\dZ/;
my $bsd = qr/\w\w\w [ \d]\d \d\d:\d\d:\d\d/;

our %args = (
    client => {
	connect => { domain => AF_UNIX },
	func => sub {
	    my $self = shift;
	    write_message($self, "no time");
	    write_message($self, "Sep 28 17:37:51 bsd time");
	    write_log($self);
	},
    },
    syslogd => {
	options => ["-z"],
    },
    server => {
	loggrep => {
	    qr/>$iso no time$/ => 1,
	    qr/>$iso bsd time$/ => 1,
	},
    },
    file => {
	loggrep => {
	    qr/^$iso $host no time$/ => 1,
	    qr/^$iso $host bsd time$/ => 1,
	},
    },
);

1;
