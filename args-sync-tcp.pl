# The TCP server closes the connection to syslogd.
# The client writes a message to Sys::Syslog native method.
# The syslogd writes it into a file and through a pipe.
# The syslogd does a TCP reconnect and passes it to loghost.
# The server receives the message on its new accepted TCP socket.
# Find the message in client, pipe, syslogd, server log.
# Check that syslogd and server close and reopen the connection.

use strict;
use warnings;
use Socket;

our %args = (
    client => {
	func => sub { write_between2logs(shift, sub {
	    my $self = shift;
	    write_message($self, get_secondlog());
	    foreach (1..300) {
		write_char($self, [1024], $_);
		# if client sends too fast, syslogd will not see everything
		sleep .01;
	    }
	    write_message($self, get_thirdlog());
	    ${$self->{server}}->loggrep("Accepted", 5, 2)
		or die ref($self), " server did not receive second log";
	})},
    },
    syslogd => {
	loghost => '@tcp://127.0.0.1:$connectport',
	loggrep => {
	    get_between2loggrep(),
	    get_charlog() => 300,
	},
    },
    server => {
	listen => { domain => AF_INET, proto => "tcp", addr => "127.0.0.1" },
	redo => 0,
	func => sub { read_between2logs(shift, sub {
	    my $self = shift;
	    if ($self->{redo}) {
		$self->{redo}--;
		return;
	    }
	    ${$self->{client}}->loggrep(get_thirdlog(), 5)
		or die ref($self), " client did not send third log";
	    shutdown(\*STDOUT, 1)
		or die "shutdown write failed: $!";
	    $self->{redo}++;
	})},
	loggrep => {
	    qr/Accepted/ => 2,
	    get_between2loggrep(),
	    get_secondlog() => 0,
	    get_thirdlog() => 0,
	},
    },
    file => {
	loggrep => {
	    get_between2loggrep(),
	    get_secondlog() => 1,
	    get_thirdlog() => 1,
	    get_charlog() => 300,
	},
    },
);

1;
