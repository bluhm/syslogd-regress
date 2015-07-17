# The syslogd listens on 127.0.0.1 TCP socket.
# The client writes non transparent framing message that is too long.
# The syslogd writes it into a file and through a pipe.
# The syslogd passes it via UDP to the loghost.
# The server receives the message on its UDP socket.
# Find the message in client, file, syslogd, server log.
# Check that the file log contains the truncated message.

use strict;
use warnings;
use constant MAXLINE => 8192;
use constant MAX_UDPMSG => 1180;

our %args = (
    client => {
	connect => { domain => AF_INET, proto => "tcp", addr => "127.0.0.1",
	    port => 514 },
	func => sub {
	    my $self = shift;
	    local $| = 1;
	    my $msg = generate_chars(MAXLINE+1);
	    print "$msg\n";
	    print STDERR "<<< $msg\n";
	    ${$self->{syslogd}}->loggrep("tcp logger .* incomplete", 5)
		or die ref($self), " syslogd did not receive incomplete";
	    write_shutdown($self);
	},
	loggrep => qr/<<< 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ/,
    },
    syslogd => {
	options => ["-T", "127.0.0.1:514"],
	loggrep => {
	    qr/non transparent framing, incomplete frame, /.
		qr/use /.(MAXLINE+1).qr/ bytes/ => 1,
	    qr/non transparent framing, use /.(MAXLINE+1).qr/ bytes/ => 1,
	},
    },
    server => {
	# >>> <13>Jul  6 22:33:32 0123456789ABC...fgh
	loggrep => qr/>>> .{19} /.generate_chars(MAX_UDPMSG-20).qr/$/,
    },
    file => {
	loggrep => generate_chars(MAXLINE).qr/$/,
    },
    pipe => { loggrep => {} },  # XXX syslogd ignore short writes to pipe
);

1;