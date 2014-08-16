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
use Socket;
use Socket6;
use Sys::Syslog qw(:standard :macros);
use IO::Socket;
use IO::Socket::INET6;

sub find_ports {
	my %args = @_;
	my $num    = delete $args{num}    // 1;
	my $domain = delete $args{domain} // AF_INET;
	my $addr   = delete $args{addr}   // "127.0.0.1";

	my @sockets = (1..$num);
	foreach my $s (@sockets) {
		$s = IO::Socket::INET6->new(
		    Proto  => "tcp",
		    Domain => $domain,
		    $addr ? (LocalAddr => $addr) : (),
		) or die "find_ports: create and bind socket failed: $!";
	}
	my @ports = map { $_->sockport() } @sockets;

	return @ports;
}

########################################################################
# Client funcs
########################################################################

sub write_log {
	syslog(LOG_INFO, "foo");
}

sub errignore {
	$SIG{PIPE} = 'IGNORE';
	$SIG{__DIE__} = sub {
		die @_ if $^S;
		warn "Error ignored";
		warn @_;
		IO::Handle::flush(\*STDERR);
		POSIX::_exit(0);
	};
}

########################################################################
# Server funcs
########################################################################

sub read_char {
	my $self = shift;
	my $max = shift // $self->{max};

	my $ctx = Digest::MD5->new();
	my $len = 0;
	if (defined($max) && $max == 0) {
		print STDERR "Max\n";
	} else {
		while (<STDIN>) {
			$len += length($_);
			$ctx->add($_);
			print STDERR ".";
			if (defined($max) && $len >= $max) {
				print STDERR "\nMax";
				last;
			}
		}
		print STDERR "\n";
	}

	print STDERR "LEN: ", $len, "\n";
	print STDERR "MD5: ", $ctx->hexdigest, "\n";
}

########################################################################
# Script funcs
########################################################################

sub check_logs {
	my ($c, $r, $s, %args) = @_;

	return if $args{nocheck};

	check_loggrep($c, $r, $s, %args);
}

sub check_loggrep {
	my ($c, $r, $s, %args) = @_;

	my %name2proc = (client => $c, syslogd => $r, server => $s);
	foreach my $name (qw(client syslogd server)) {
		my $p = $name2proc{$name}
		    or next;
		my $pattern = $args{$name}{loggrep} or next;
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

1;
