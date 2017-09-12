# The client writes a message to Sys::Syslog native method.
# The syslogd writes it into a file and through a pipe and to tty.
# The syslogd passes it via UDP to the loghost.
# The server receives the message on its UDP socket.
# Find the message in client, file, pipe, console, user, syslogd, server log.

use strict;
use warnings;

our %args = (
    client => {
	connectproto => "none",
	redo => [
	    { connect => {
		proto  => "udp",
		domain => AF_INET,
		addr   => "127.0.0.1",
		port   => 514,
	    }},
	    { logsock => {
		type  => "native",
	    }},
	],
	func => sub {
	    my $self = shift;
	    write_message($self, "client proto: ". $self->{connectproto});
	    close($self->{cs}) if $self->{cs};
	    if (my $connect = shift @{$self->{redo}}) {
		$self->{connectproto}  = $connect->{proto};
		$self->{connectdomain} = $connect->{domain};
		$self->{connectaddr}   = $connect->{addr};
		$self->{connectport}   = $connect->{port};
	    } else {
		delete $self->{connectdomain};
		$self->{logsock} = { type => "native" };
		setlogsock($self->{logsock})
		    or die ref($self), " setlogsock failed: $!";
		write_log($self);
		undef $self->{redo};
	    }
	},
    },
);

1;
