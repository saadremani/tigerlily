# -*- Perl -*-
# $Header: /home/mjr/tmp/tlilycvs/lily/tigerlily2/extensions/server.pl,v 1.26 2000/09/09 06:07:26 mjr Exp $

use strict;

use TLily::UI;
use TLily::Server::SLCP;
use TLily::Event;

=head1 NAME

server.pl - Server interface commands

=head1 DESCRIPTION

This extension contains commands for interfacing with servers.

=head1 COMMANDS

=over 10

=item %connect

Connect to a server.  See "%help %connect".

=item %close

Close a connection to the current active server.  See "%help %close".

=head1 UI COMMANDS

=item next-server

Change the current active server to the next server in the list of servers.
Bound to C-q by default.

=cut

sub connect_command {
    my($ui, $arg) = @_;
    my(@argv) = split /\s+/, $arg;
    my $auto_login = 1;
    TLily::Event::keepalive();

    while ((@argv) && ($argv[0] =~ /^-/)) {
	my $opt = shift @argv;
	if ($opt eq "-nologin") {
	    $auto_login = 0;
	} else {
	    $ui->print("(unknown switch \"$opt\")\n");
	    return;
	}
    }

    my($host, $port, $user, $pass) = @argv;

    if (!defined $host) {
	if (!defined($config{server})) {
	    $ui->print("(no default server specified)\n");
	    return;
	}

	$host = $config{server};
	$port = $config{port};
    }

    # Expand host aliases.
    if (!defined($port) && $config{server_info}) {
	foreach my $i (@{$config{server_info}}) {
	    if ($host eq $i->{alias}) {
		($host, $port) = ($i->{host}, $i->{port});
		last;
	    }
	}
    }

    # Pick out autologin information.
    if ($auto_login) {
	if ($config{server_info}) {
	    foreach my $i (@{$config{server_info}}) {
		if ($host eq $i->{host}) {
		    $port = $i->{port} if (!defined $port);
		    if ($port == $i->{port}) {
			($user, $pass) = ($i->{user}, $i->{pass});
			last;
		    }
		}
	    }
	}
    }

    my $server;
    $server = TLily::Server::SLCP->new(host      => $host,
				       port      => $port,
				       user      => $user,
				       password  => $pass,
				       'ui_name' => $ui->name);
    return unless $server;

    $server->activate();
}
command_r('connect' => \&connect_command);
shelp_r('connect' => "Connect to a server.");
help_r('connect' => "
Usage: %connect [host] [port]

Create a new connection to a server.
");


sub close_command {
    my($ui, $arg) = @_;
    my(@argv) = split /\s+/, $arg;
    TLily::Event::keepalive();

    my $server = active_server();
    if (!$server) {
	$ui->print("(you are not currently connected to a server)\n");
	return;
    }

    $ui->print("(closing connection to \"", scalar($server->name()), "\")\n");
    $server->terminate();
    return;
}
command_r('close' => \&close_command);
shelp_r('close' => "Close the connection to the current server.");
help_r('close' => "
Usage: %close

Close the connection to the current server.
");


sub next_server {
    my($ui, $command, $key) = @_;

    my @server = TLily::Server::find();
    my $server = active_server() || $server[-1];

    my $idx = 0;
    foreach (@server) {
	last if ($_ == $server);
	$idx++;
    }

    if (@server == 0) {
        $ui->print("(You are not connected to any servers)\n");
        return;
    }

    $idx = ($idx + 1) % @server;
    $server = $server[$idx];
    $server->activate();

    if (@server == 1) {
        return;
    }

    $ui->print("(switching to server \"", scalar($server->name()), "\")\n");
    return;
}
TLily::UI::command_r("next-server" => \&next_server);
TLily::UI::bind("C-q" => "next-server");


sub send_handler {
    my($e, $h) = @_;
    $e->{server}->sendln(join(",",@{$e->{RECIPS}}),$e->{dtype},$e->{text});
}
event_r(type => 'user_send',
	call => \&send_handler);

sub to_server {
    my($e, $h) = @_;
    my $server = $e->{server} || active_server();

    if (! $server) {
	# we aren't connected to a server
        if ($e->{text} == "" && $config{smartexit}) {
            TLily::Event::keepalive();
            exit;
        }
	return 1;
    }

    $server->command($e->{ui}, $e->{text});
}
event_r(type  => "user_input",
	order => "after",
	call  => \&to_server);

1;
