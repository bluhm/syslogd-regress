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
use Errno;
use List::Util qw(first);
use Socket;
use Socket6;
use Sys::Syslog qw(:standard :extended :macros);
use IO::Socket;
use IO::Socket::INET6;

my $testlog = "syslogd regress test log message";
my $downlog = "syslogd regress client shutdown";

########################################################################
# Client funcs
########################################################################

sub write_log {
	my $self = shift;

	if ($self->{connect}) {
		print $testlog;
	} else {
		syslog(LOG_INFO, $testlog);
	}
	write_shutdown($self, @_);
}

sub write_shutdown {
	my $self = shift;

	setlogsock("native")
	    or die ref($self), " setlogsock native failed: $!";
	syslog(LOG_NOTICE, $downlog);
}

########################################################################
# Server funcs
########################################################################

sub read_log {
	my $self = shift;

	for (;;) {
		defined(sysread(STDIN, my $line, 8194))
		    or die "read log line failed: $!";
		chomp $line;
		print STDERR ">>> $line\n";
		last if $line =~ /$downlog/;
	}
}

########################################################################
# Script funcs
########################################################################

sub check_logs {
	my ($c, $r, $s, %args) = @_;

	return if $args{nocheck};

	check_loggrep($c, $r, $s, %args);
	check_outgrep($r, %args);
}

sub check_loggrep {
	my ($c, $r, $s, %args) = @_;

	my %name2proc = (client => $c, syslogd => $r, server => $s);
	foreach my $name (qw(client syslogd server)) {
		next if $args{$name}{nocheck};
		my $p = $name2proc{$name} or next;
		my $pattern = $args{$name}{loggrep} || $testlog;
		$pattern = [ $pattern ] unless ref($pattern) eq 'ARRAY';
		foreach my $pat (@$pattern) {
			if (ref($pat) eq 'HASH') {
				while (my($re, $num) = each %$pat) {
					my @matches = $p->loggrep($re);
					@matches == $num
					    or die "$name matches @matches: ",
					    "$re => $num";
				}
			} else {
				$p->loggrep($pat)
				    or die "$name log missing pattern: $pat";
			}
		}
	}
}

sub check_outgrep {
	my ($r, %args) = @_;

	foreach my $name (qw(file pipe)) {
		next if $args{$name}{nocheck};
		my $file = $r->{"out$name"} or next;
		my $pattern = $args{$name}{loggrep} || $testlog;
		$pattern = [ $pattern ] unless ref($pattern) eq 'ARRAY';
		foreach my $pat (@$pattern) {
			if (ref($pat) eq 'HASH') {
				while (my($re, $num) = each %$pat) {
					my @matches = filegrep($file, $re);
					@matches == $num
					    or die "$name matches @matches: ",
					    "$re => $num";
				}
			} else {
				filegrep($file, $pat)
				    or die "$name log missing pattern: $pat";
			}
		}
	}
}

sub filegrep {
	my ($file, $pattern) = @_;

	open(my $fh, '<', $file)
	    or die "Open file $file for reading failed: $!";
	return wantarray ?
	    grep { /$pattern/ } <$fh> : first { /$pattern/ } <$fh>;
}

1;
