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
use Socket;
use Socket6;

use Client;
use Syslogd;
use Server;
require 'funcs.pl';

sub usage {
	die "usage: syslogd.pl [test-args.pl]\n";
}

my $testfile;
our %args;
if (@ARGV and -f $ARGV[-1]) {
	$testfile = pop;
	do $testfile
	    or die "Do test file $testfile failed: ", $@ || $!;
}
@ARGV == 0 or usage();

my($sport) = find_ports();
my $s = Server->new(
    func                => \&read_log,
    listendomain        => AF_INET,
    listenaddr          => "127.0.0.1",
    listenport          => $sport,
    %{$args{server}},
    testfile            => $testfile,
) unless $args{client}{noserver};
my $r = Syslogd->new(
    connectdomain       => AF_INET,
    connectaddr         => "127.0.0.1",
    connectport         => $sport,
    %{$args{syslogd}},
    testfile            => $testfile,
);
my $c = Client->new(
    func                => \&write_log,
    %{$args{client}},
    testfile            => $testfile,
) unless $args{client}{noclient};

$s->run if $s;
$r->run;
$r->up;
$c->run->up if $c;
$s->up if $s;

$c->down if $c;
$s->down if $s;
$r->kill_child;
$r->down;

check_logs($c, $r, $s, %args);
