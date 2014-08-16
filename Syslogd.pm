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
	$args{up} ||= "Started";
	$args{down} ||= "terminating";
	$args{func} = sub { Carp::confess "$class func may not be called" };
	$args{conffile} ||= "syslogd.conf";
	my $self = Proc::new($class, %args);

	if (substr($self->{conffile}, 0, 1) ne "/") {
		$self->{conffile} = getcwd()."/".$self->{conffile};
	}
	open(my $fh, '>', $self->{conffile})
	    or die ref($self), " conf file $self->{conffile} create failed: $!";
	close $fh;

	return $self;
}

sub up {
	my $self = Proc::up(shift, @_);
	my $timeout = shift || 10;
	my $regex = "syslogd: started";
	$self->loggrep(qr/$regex/, $timeout)
	    or croak ref($self), " no $regex in $self->{logfile} ".
		"after $timeout seconds";
	return $self;
}

sub child {
	my $self = shift;
	print STDERR $self->{up}, "\n";
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

1;
