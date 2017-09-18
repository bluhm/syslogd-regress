# Create a log file on a file system that can be easily filled.
# The client writes messages to Sys::Syslog native method.
# While writing messages, the client fills the log file system.
# The syslogd writes it into a file and through a pipe and to tty.
# The syslogd passes it via UDP to the loghost.
# The server receives the message on its UDP socket.
# Find the message in client, file, pipe, console, user, syslogd, server log.
# Check that syslogd error 'No space left on device' error is logged to server.
# Check that kernel error 'file system full' error is logged.
# Check that 'dropped messages to file' is logged by server and file.

use strict;
use warnings;
use Errno ':POSIX';
use File::Path qw(remove_tree);
use Time::HiRes;

my @errors = (ENOSPC);
my $errors = "(". join("|", map { $! = $_ } @errors). ")";

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
	    ${$self->{syslogd}}->loggrep(get_firstlog(), 5)
		or die ref($self), " first log not in syslogd log";
	    undef $!;
	    for (my $i = 0; $i < 100000; $i++) {
		syswrite($big, "regress syslogd file system full\n", 33)
		    or last;
	    }
	    $!{ENOSPC}
		or die ref($self), " fill $fsbig failed: $!";
	    ${$self->{syslogd}}->loggrep(qr/file system full/, 5)
		or die ref($self), " file system full not in syslogd log";
	    # a single message still fits, write 4 KB logs to reach next block
	    write_lines($self, 100, 30);
	    ${$self->{syslogd}}->loggrep(qr/write to file .* $errors/, 10)
		or die ref($self), " write to file error not in syslogd log";
	    close($big);
	    unlink($fsbig)
		or die ref($self), " remove $fsbig failed: $!";
	    # wait until syslogd has processed everything
	    write_message($self, get_secondlog());
	    ${$self->{server}}->loggrep(get_secondlog(), 10)
		or die ref($self), " second log not in server log";
	    write_message($self, get_thirdlog());
	    write_log($self);
	},
    },
    syslogd => {
	outfile => $fslog,
    },
    server => {
	loggrep => {
	    get_testgrep() => 1,
	    get_firstlog() => 1,
	    get_secondlog() => 1,
	    get_thirdlog() => 1,
	    qr/syslogd\[\d+\]: write to file "$fslog": /.
		qr/No space left on device/ => '>=1',
	    qr/bsd: .* on $fspath: file system full/ => '>=1',
	    qr/syslogd\[\d+\]: dropped \d+ messages to file "$fslog"/ => '>=1',
	},
    },
    file => {
	loggrep => {
	    get_testgrep() => 1,
	    get_firstlog() => 1,
	    get_thirdlog() => 1,
	    qr/syslogd\[\d+\]: write to file "$fslog": /.
		qr/No space left on device/ => 0,
	    qr/bsd: .* on $fspath: file system full/ => 1,
	    qr/syslogd\[\d+\]: dropped \d+ messages to file "$fslog"/ => '>=1',
	},
    },
);

1;
