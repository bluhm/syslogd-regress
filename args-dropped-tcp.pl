# The client writes 300 messages to Sys::Syslog native method.
# The syslogd writes it into a file and through a pipe.
# The syslogd passes it via TCP to the loghost.
# The server blocks the message on its TCP socket.
# The server waits until the client as written all messages.
# The server receives the message on its TCP socket.
# The client waits until the server as read the first message.
# Find the message in client, file, pipe, syslogd, server log.
# Check that the 300 messages are in syslogd and file log.
# Check that the dropped message is in server and file log.

use strict;
use warnings;
use Socket;

my $msg = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

our %args = (
    client => {
	func => sub {
	    my $self = shift;
	    write_message($self, get_firstlog());
	    foreach (1..300) {
		write_char($self, [1024], $_);
		# if client sends too fast, syslogd will not see everything
		sleep .01;
	    }
	    write_message($self, get_testlog());
	    ${$self->{server}}->loggrep(get_firstlog(), 5)
		or die ref($self), " server did not receive firstlog";
	    write_shutdown($self);
	},
    },
    syslogd => {
	loghost => '@tcp://localhost:$connectport',
	loggrep => {
	    $msg => 300,
	    get_firstlog() => 1,
	    get_testlog() => 1,
	},
    },
    server => {
	listen => { domain => AF_UNSPEC, proto => "tcp", addr => "localhost" },
	func => sub {
	    my $self = shift;
	    ${$self->{client}}->loggrep(get_testlog(), 5)
		or die ref($self), " client did not send testlog";
	    read_log($self, @_);
	},
	loggrep => {
	    get_firstlog() => 1,
	    get_testlog() => 0,
	    qr/syslogd: loghost "\@tcp:.*" dropped \d+ messages/ => 1,
	},
    },
    file => {
	loggrep => {
	    $msg => 300,
	    get_firstlog() => 1,
	    get_testlog() => 1,
	    qr/syslogd: loghost "\@tcp:.*" dropped \d+ messages/ => 1,
	},
    },
);

1;
