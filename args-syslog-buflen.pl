# The client writes a long message to Sys::Syslog native method.
# The syslogd writes it into a file and through a pipe.
# The syslogd passes it via TCP to the loghost.
# The server receives the message on its TCP socket.
# Find the message in client, file, pipe, syslogd, server log.
# Check that 8000 bytes messages can be processed.

use strict;
use warnings;
use Socket;
use Sys::Hostname;
use constant BUFLEN => 8192;

(my $host = hostname()) =~ s/\..*//;

our %args = (
    client => {
	logsock => { type => "native" },
	func => sub {
	    my $self = shift;
	    write_chars($self, 4000);
	    write_shutdown($self);
	},
	loggrep => { get_charlog() => 1 },
    },
    syslogd => {
	loghost => '@tcp://localhost:$connectport',
	loggrep => {
	    qr/[gs]etsockopt bufsize/ => 0,
	    get_charlog() => 1,
	},
    },
    server => {
	listen => { domain => AF_UNSPEC, proto => "tcp", addr => "localhost" },
	loggrep => { get_charlog() => 1 },
    },
    pipe => {
	loggrep => { get_charlog() => 1 },
    },
    file => {
	loggrep => { get_charlog() => 1 },
    },
);

1;
