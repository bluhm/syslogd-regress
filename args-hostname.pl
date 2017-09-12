# The client writes a message to Sys::Syslog native method.
# The syslogd writes it into a file and through a pipe and to tty.
# The syslogd passes it via UDP to the loghost.
# The server receives the message on its UDP socket.
# Find the message in client, file, pipe, console, user, syslogd, server log.

use strict;
use warnings;
use Socket;
use Sys::Hostname;

(my $host = hostname()) =~ s/\..*//;

our %args = (
    client => {
	redo => [
	    { connect => {
		proto  => "udp",
		domain => AF_INET,
		addr   => "127.0.0.1",
		port   => 514,
	    }},
	    { connect => {
		proto  => "tcp",
		domain => AF_INET,
		addr   => "127.0.0.1",
		port   => 514,
	    }},
	    { connect => {
		proto  => "tls",
		domain => AF_INET,
		addr   => "127.0.0.1",
		port   => 6514,
	    }},
	    { logsock => {
		type  => "native",
	    }},
	],
	func => sub { redo_connect( shift, sub {
	    my $self = shift;
	    write_message($self, "client connect proto: ".
		$self->{connectproto}) if $self->{connectproto};
	    write_message($self, "client logsock type: ".
		$self->{logsock}{type}) if $self->{logsock};
	})},
    },
    syslogd => {
	options => [qw(-h -U 127.0.0.1:514 -T 127.0.0.1:514 -S 127.0.0.1:6514)],
    },
    server => {
	loggrep => {
	    qr/ client connect / => 3,
	    qr/:\d\d $host client connect proto: udp$/ => 1,
	    qr/:\d\d $host client connect proto: tcp$/ => 1,
	    qr/:\d\d $host client connect proto: tls$/ => 1,
	    qr/ client logsock / => 1,
	    qr/:\d\d $host syslogd-.*: client logsock type: native$/ => 1,
	},
    },
);

1;
