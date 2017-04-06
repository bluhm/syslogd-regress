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
