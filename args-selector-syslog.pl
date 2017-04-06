# The client connects with TCP.
# The syslogd writes local messages into multiple files depending on priority.
# The syslogd writes it into a file and through a pipe.
# The syslogd passes it via UDP to the loghost.
# The server receives the message on its UDP socket.
# Find the message in client, file, pipe, syslogd, server log.
# Check that local syslog messages end up the correct priority file.

use strict;
use warnings;
use Sys::Syslog;

my %selector2messages = (
    "syslog.*"       => [qw{ start .*accepted .*close exiting.* }],
    "syslog.debug"   => [qw{ start .*accepted .*close exiting.* }],
    "syslog.info"    => [qw{ start .*accepted .*close exiting.* }],
    "syslog.notice"  => [qw{ exiting.* }],
    "syslog.warning" => [qw{ exiting.* }],
    "syslog.err"     => [qw{ exiting.* }],
    "syslog.crit"    => [],
    "syslog.alert"   => [],
    "syslog.emerg"   => [],
    "syslog.none"    => [],
);

sub selector2config {
    my %s2m = @_;
    my $conf = "";
    my $i = 0;
    foreach my $sel (sort keys %s2m) {
	$conf .= "$sel\t\$objdir/file-$i.log\n";
	$i++;
    }
    return $conf;
}

sub messages2loggrep {
    my %s2m = @_;

    my %allmsg;
    @allmsg{map { @$_} values %s2m} = ();

    my @loggrep;
    foreach my $sel (sort keys %s2m) {
	my @m = @{$s2m{$sel}};
	my %msg;
	@msg{@m} = ();
	my %nomsg = %allmsg;
	delete @nomsg{@m};
	push @loggrep, {
	    (map { qr/: $_$/ => 1 } sort keys %msg),
	    (map { qr/: $_$/ => 0 } sort keys %nomsg),
	};
    }
    return @loggrep;
}

our %args = (
    client => {
	logsock => { type => "tcp", host => "127.0.0.1", port => 514 },
    },
    syslogd => {
	options => ["-T", "127.0.0.1:514"],
	conf => selector2config(%selector2messages),
    },
    multifile => [
	(map { { loggrep => $_ } } (messages2loggrep(%selector2messages))),
    ],
);

1;
