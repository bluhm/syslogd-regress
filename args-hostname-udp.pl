# The client writes messages with various host name formats via UDP.
# The syslogd writes them into a file and through a pipe and to tty.
# The syslogd adds hostname if necessary, and passes them to loghost.
# The server receives the messages on its UDP socket.
# Check that the hostname in file and server log is correct.

use strict;
use warnings;
use Socket;
use Sys::Hostname;

(my $host = hostname()) =~ s/\..*//;

our %args = (
    client => {
	connect => { domain => AF_INET, addr => "127.0.0.1", port => 514,
	    proto => "udp" },
	func => sub {
	    my $self = shift;
	    write_message($self, $_) foreach (
		"<14>2021-09-17T00:00:00Z client-host prog[1234]: foo",
		"<14>2021-09-17T00:00:00Z client.host prog[1234]: foo",
		"<14>2021-09-17T11:11:11Z 1.2.3.4 prog[1234]: foo",
		"<14>2021-09-17T22:22:22Z - prog[1234]: foo",
		"<14>2021-09-17T33:33:33Z prog[1234]: foo",
	    );
	    write_log($self);
	},
    },
    syslogd => {
	options => [qw(-n -U 127.0.0.1:514)],
    },
    server => {
	loggrep => {
	    qr/<14>2021-09-17T00:00:00Z client-host prog\[1234\]:/ => 1,
	    qr/<14>2021-09-17T11:11:11Z 1.2.3.4 prog\[1234\]:/ => 1,
	    qr/<14>2021-09-17T22:22:22Z - prog\[1234\]:/ => 1,
	    qr/<14>2021-09-17T33:33:33Z prog\[1234\]:/ => 1,
	},
    },
    file => {
	# XXX 127.0.0.1
	loggrep => {
	    qr/2021-09-17T00:00:00Z 127.0.0.1 client-host prog\[1234\]:/ => 1,
	    qr/2021-09-17T11:11:11Z 127.0.0.1 1.2.3.4 prog\[1234\]:/ => 1,
	    qr/2021-09-17T22:22:22Z 127.0.0.1 - prog\[1234\]:/ => 1,
	    qr/2021-09-17T33:33:33Z 127.0.0.1 prog\[1234\]:/ => 1,
	},
    },
);

1;
