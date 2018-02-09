# The client writes messages to unix domain sockets and file.
# The syslogd -a creates unix domain sockets but not over an existing file.
# The syslogd passes message via UDP to the loghost.
# The server receives the messages on its UDP socket.
# Find the message in client, file, pipe, syslogd, server log.
# Check client could not write to existing regular file.
# Check that the file log contains only the message from unix socket.
# Check that unix socket was removed, but regular file preserved..

use strict;
use warnings;
use Errno ':POSIX';
use IO::Socket::UNIX;

my @errors = (ENOTSOCK);
my $errors = "(". join("|", map { $! = $_ } @errors). ")";

{
    unlink("file.sock");
    open(my $fh, '>', "file.sock")
	or die "Create 'file.sock' failed: $!";
}

our %args = (
    client => {
	func => sub {
	    my $self = shift;
	    write_unix($self, "unix.sock");
	    eval { write_unix($self, "file.sock") };
	    warn $@;
	    write_shutdown($self);
	},
	loggrep => {
	    qr/connect to file.sock unix socket failed: $errors/ => 1,
	},
    },
    syslogd => {
	options => [ "-a" => "unix.sock", "-a" => "file.sock" ],
	loggrep => {
	    qr/connect unix "file.sock": $errors/ => 1,
	},
    },
    file => {
	loggrep => {
	    "unix.sock unix socket" => 1,
	    "file.sock unix socket" => 0,
	},
    },
    check => sub {
	-e "unix.sock" and die "Unix socket 'unix.sock' exists";
	-f "file.sock" or die "Plain file 'file.sock' missing";
    },
);

1;
