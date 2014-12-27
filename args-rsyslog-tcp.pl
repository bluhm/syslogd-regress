# Test with rsyslogd as receiver.
# The client writes a message to Sys::Syslog native method.
# The syslogd writes it into a file and through a pipe.
# The syslogd passes it via TCP to the rsyslogd.
# The rsyslogd receives the message on its TCP socket.
# Find the message in client, file, pipe, syslogd, rsyslogd log.
# Check that the message is in the rsyslogd out file.

use strict;
use warnings;

our %args = (
    rsyslogd => {
	listen => { proto => "tcp" },
    },
);

1;
