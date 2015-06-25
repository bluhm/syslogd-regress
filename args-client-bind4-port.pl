# Syslog binds UDP socket to 127.0.0.1 and port.
# The client writes a message to Sys::Syslog UDP method.
# The syslogd writes it into a file and through a pipe.
# The syslogd passes it via UDP to the loghost.
# The server receives the message on its UDP socket.
# Find the message in client, file, pipe, syslogd, server log.
# Check that the file log contains the localhost name.
# Check that fstat contains a bound UDP socket.

use strict;
use warnings;
require 'funcs.pl';


my $port = find_ports();

our %args = (
    client => {
	logsock => { type => "udp", host => "127.0.0.1", port => $port },
    },
    syslogd => {
	options => ["-U", "127.0.0.1:$port"],
	fstat => qr/ internet dgram udp 127.0.0.1:$port$/,
    },
    file => {
	loggrep => qr/ localhost syslogd-regress\[\d+\]: /. get_testlog(),
    },
);

1;
