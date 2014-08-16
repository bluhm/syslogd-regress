#	$OpenBSD$

# Copyright (c) 2010-2014 Alexander Bluhm <bluhm@openbsd.org>
# Copyright (c) 2014 Florian Riehm <mail@friehm.de>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use strict;
use warnings;

package Syslogd;
use parent 'Proc';
use Carp;
use Cwd;
use File::Basename;

sub new {
	my $class = shift;
	my %args = @_;
	$args{logfile} ||= "syslogd.log";
	$args{up} ||= "syslogd: started";
	$args{down} ||= "syslogd: exiting";
	$args{func} = sub { Carp::confess "$class func may not be called" };
	$args{conffile} ||= "syslogd.conf";
	$args{outfile} ||= "file.log";
	$args{outpipe} ||= "pipe.log";
	my $self = Proc::new($class, %args);
	$self->{connectaddr}
	    or croak "$class connect addr not given";

	_make_abspath(\$self->{$_}) foreach (qw(conffile outfile outpipe));

	open(my $fh, '>', $self->{conffile})
	    or die ref($self), " create conf file $self->{conffile} failed: $!";
	print $fh "*.*\t$self->{outfile}\n";
	print $fh "*.*\t|dd of=$self->{outpipe} status=none\n";
	my $loghost = "\@$self->{connectaddr}";
	$loghost .= ":$self->{connectport}" if $self->{connectport};
	print $fh "*.*\t$loghost\n";
	close $fh;

	open($fh, '>', $self->{outfile})
	    or die ref($self), " create log file $self->{outfile} failed: $!";
	close $fh;

	open($fh, '>', $self->{outpipe})
	    or die ref($self), " create pipe file $self->{outpipe} failed: $!";
	close $fh;
	chmod(0666, $self->{outpipe})
	    or die ref($self), " chmod pipe file $self->{outpipe} failed: $!";

	return $self;
}

sub child {
	my $self = shift;
	my @sudo = $ENV{SUDO} ? $ENV{SUDO} : ();

	my @pkill = (@sudo, "pkill", "-x", "syslogd");
	my @pgrep = ("pgrep", "-x", "syslogd");
	system(@pkill) && $? != 256
	    and die "System '@pkill' failed: $?";
	while ($? == 0) {
		print STDERR "syslogd still running\n";
		system(@pgrep) && $? != 256
		    and die "System '@pgrep' failed: $?";
	}
	print STDERR "syslogd not running\n";

	my @ktrace = $ENV{KTRACE} ? ($ENV{KTRACE}, "-i") : ();
	my $syslogd = $ENV{SYSLOGD} ? $ENV{SYSLOGD} : "syslogd";
	my @cmd = (@sudo, @ktrace, $syslogd, "-d", "-f", $self->{conffile});
	print STDERR "execute: @cmd\n";
	exec @cmd;
	die "Exec '@cmd' failed: $!";
}

sub _make_abspath {
	my $file = ref($_[0]) ? ${$_[0]} : $_[0];
	if (substr($file, 0, 1) ne "/") {
		$file = getcwd(). "/". $file;
		${$_[0]} = $file if ref($_[0]);
	}
	return $file;
}

1;
