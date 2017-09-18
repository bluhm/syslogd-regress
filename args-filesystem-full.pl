# The client writes a message to Sys::Syslog native method.
# The syslogd writes it into a file and through a pipe and to tty.
# The syslogd passes it via UDP to the loghost.
# The server receives the message on its UDP socket.
# Find the message in client, file, pipe, console, user, syslogd, server log.

use strict;
use warnings;
use Errno;
use File::Path qw(remove_tree);
use Time::HiRes;

my $fspath = "/mnt/regress-syslogd";
my $fslog = "$fspath/file.log";
my $fsbig = "$fspath/big";

remove_tree($fspath, { safe => 1, keep_root => 1 });
open(my $log, '>', $fslog)
    or die "Create $fslog failed: $!";

our %args = (
    client => {
	func => sub {
	    my $self = shift;
	    open(my $big, '>', $fsbig)
		or die ref($self), " create $fsbig failed: $!";
	    write_message($self, get_firstlog());
	    sleep .1;
	    undef $!;
	    for (my $i = 0; $i < 100000; $i++) {
		syswrite($big, "regress syslogd file system ful\n", 32)
		    or last;
	    }
	    $!{ENOSPC}
		or die ref($self), " fill $fsbig failed: $!";
	    write_message($self, get_secondlog());
	    # a single message still fits, write 4 KB logs to reach next block
	    write_lines($self, 50, 60);
	    sleep 5;
	    close($big);
	    unlink($fsbig)
		or die ref($self), " remove $fsbig failed: $!";
	    sleep .1;
	    write_message($self, get_thirdlog());
	    write_log($self);
	},
    },
    syslogd => {
	conf => "*.*\t$fslog\n",
    }
);

1;
