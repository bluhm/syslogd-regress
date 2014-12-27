#	$OpenBSD$

# Copyright (c) 2010-2014 Alexander Bluhm <bluhm@openbsd.org>
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

package RSyslogd;
use parent 'Proc';
use Carp;

sub new {
	my $class = shift;
	my %args = @_;
	$args{logfile} ||= "rsyslogd.log";
	$args{up} ||= "rsyslogd: started";
	$args{down} ||= "rsyslogd: exiting";
	$args{func} = sub { Carp::confess "$class func may not be called" };
	$args{conffile} ||= "rsyslogd.conf";
	my $self = Proc::new($class, %args);

	# substitute variables in config file
	my $listendomain = $self->{listendomain}
	    or croak "$class listen domain not given";
	my $listenaddr = $self->{listenaddr}
	    or croak "$class listen address not given";
	my $listenproto = $self->{listenproto} || "udp";
	my $listenport = $self->{listenport} ||= find_ports(
	    num    => 1,
	    domain => $listendomain,
	    addr   => $listenaddr,
	    proto  => $listenproto,
	);

	open(my $fh, '>', $self->{conffile})
	    or die ref($self), " create conf file $self->{conffile} failed: $!";
	print $fh $self->{conf} if $self->{conf};
	close $fh;

	return $self;
}

sub child {
	my $self = shift;

	my @cmd = ("rsyslogd", "-n", "-f", $self->{conffile});
	print STDERR "execute: @cmd\n";
	exec @cmd;
	die ref($self), " exec '@cmd' failed: $!";
}

1;
