# The syslogd listens on localhost TLS socket.
# The client writes a message into a localhost TLS socket.
# The syslogd writes it into a file and through a pipe.
# The syslogd passes it via UDP to the loghost.
# The server receives the message on its UDP socket.
# Find the message in client, file, pipe, syslogd, server log.
# Check that the file log contains the hostname and message.

use strict;
use warnings;
use Socket;

our %args = (
    client => {
	connect => { domain => AF_UNSPEC, proto => "tls", addr => "localhost",
	    port => 6514 },
	sslcert => "client.crt",
	sslkey => "client.key",
	loggrep => {
	    qr/connect sock: (127.0.0.1|::1) \d+/ => 1,
	    get_testgrep() => 1,
	},
    },
    syslogd => {
	options => ["-S", "localhost", "-K", "ca.crt"],
	ktrace => {
	    qr{NAMI  "ca.crt"} => 1,
	},
	loggrep => {
	    qr{Server CAfile ca.crt} => 1,
	},
    },
);

1;
