package CJ::command::bacon;
use strict;

use CGI qw/escape unescape/;

our $TYPE     = "all";
our $POSITION = -1;
our $LAST     = 1;
our $RE       = qr/\bbacon\s+(.*)\s*$/i;

our $bacon_url = 'http://oracleofbacon.org/movielinks.php?a=Kevin+Bacon'
    . '&end_year=2050&start_year=1850&game=0&u0=on';
foreach my $g ( 0 .. 27 ) {
    $bacon_url .= "&g$g=on";
}

sub _scrape_bacon {
    my ($content) = shift;

    if ( $content =~ /The Oracle cannot find/ ) {
        $content =~ s/.*?(The Oracle cannot find)/\1/sm;
        $content =~ s/Arnie.*//sm;
        return "No match.";
    }
    elsif ( $content =~ /There are \d+ people named/ ) {
        return "That's not a unique name, sorry.";
    }

    $content =~ s/.*<div id="main">//sm;
    $content =~ s/(Kevin Bacon)<\/a>.*/$1/sm;
    $content =~ s/<script.*?<\/script>//smg;

    $content = CJ::cleanHTML($content);

    return $content;
}

sub response {
    my ($event) = @_;
    $event->{VALUE} =~ $RE;
    my $term = $1;

    if ( lc($term) eq 'kevin bacon' ) {
        CJ::dispatch( $event,
            'Kevin Bacon has a Bacon number of 0.'
        );
        return;
    }
    elsif ( lc($term) eq 'coke' ) {
        CJ::dispatch( $event, 'Heart attack in a glass, baby.' );
        return;
    }
    if ( $term =~ m/ \s* (\w+) \s* , \s* (\w+) \s+ \(([ivxlcm]*)\) /smix ) {
        $term = "$2 $1 ($3)";
    }

    $term = escape($term);
    my $url = $bacon_url . "&b=$term";
    CJ::add_throttled_HTTP(
        url      => $url,
        ui_name  => 'main',
        callback => sub {
            my ($response) = @_;
            CJ::dispatch( $event, _scrape_bacon( $response->{_content} ) );
        }
    );
    return;
}

sub help {
    return "Find someone's bacon number using http://oracleofbacon.org/."
        . "Usage: bacon <actor>";
}

1;
