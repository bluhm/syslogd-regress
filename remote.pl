#!/usr/bin/perl
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
use File::Basename;
use File::Copy;
use Socket;
use Socket6;

use Client;
use Syslogd;
use Server;
use Remote;
require 'funcs.pl';

sub usage {
	die <<"EOF";
usage:
    remote.pl forwardaddr udpport test-args.pl
	Only start remote syslogd on local machine.
    remote.pl localaddr remoteaddr remotessh test-args.pl
	Run test with local server.  Remote syslogd is
	started automatically with ssh on remotessh.
EOF
}

usage() unless @ARGV and -f $ARGV[-1];
my $testfile = pop;
our %args;
do $testfile
    or die "Do test file $testfile failed: ", $@ || $!;
my $mode =
	@ARGV == 2 ? "syslog"  :
	@ARGV == 3 ? "local"   :
	usage();

my $r;
if ($mode eq "syslog") {
	$r = Syslogd->new(
	    %{$args{syslogd}},
	    forwarddomain       => AF_INET,
	    forwardaddr         => $ARGV[0],
	    forwardport         => $ARGV[1],
	    logfile             => dirname($0)."/remote.log",
	    conffile            => dirname($0)."/syslogd.conf",
	    testfile            => $testfile,
	);
	open(my $log, '<', $r->{logfile})
	    or die "Remote log file open failed: $!";
	$SIG{__DIE__} = sub {
		die @_ if $^S;
		copy($log, \*STDERR);
		warn @_;
		exit 255;
	};
	copy($log, \*STDERR);
	$r->run;
	copy($log, \*STDERR);
	$r->up;
	copy($log, \*STDERR);
	print STDERR "listen sock: $ARGV[1] $rport\n";

	my $c = Client->new(
	    func                => \&write_char,
	    %{$args{client}},
	    testfile            => $testfile,
	) unless $args{client}{noclient};
	$c->run->up unless $args{client}{noclient};
	$c->down unless $args{client}{noclient};

	<STDIN>;
	copy($log, \*STDERR);
	print STDERR "stdin closed\n";
	$r->kill_child;
	$r->down;
	copy($log, \*STDERR);

	exit;
}

my $s = Server->new(
    func                => \&read_char,
    redo                => $redo,
    %{$args{server}},
    listendomain        => AF_INET,
    listenaddr          => ($mode eq "auto" ? $ARGV[1] : undef),
    listenport          => ($mode eq "manual" ? $ARGV[0] : undef),
    testfile            => $testfile,
) unless $args{server}{noserver};

$r = Remote->new(
    logfile             => "syslogd.log",
    %{$args{syslogd}},
    remotessh           => $ARGV[3],
    listenaddr          => $ARGV[2],
    connectaddr         => $ARGV[1],
    connectport         => $s ? $s->{listenport} : 1,
    testfile            => $testfile,
);
$r->run->up;

$s->run unless $args{server}{noserver};
$s->up unless $args{server}{noserver};

$s->down unless $args{server}{noserver};
$r->close_child;
$r->down;

check_logs($c, $r, $s, %args);
