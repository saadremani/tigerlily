# -*- Perl -*-
# $Header: /home/mjr/tmp/tlilycvs/lily/tigerlily2/extensions/applescript.pl,v 1.1 2003/08/12 02:47:32 coke Exp $

use TLily::Version;
use strict;

sub applescript_cmd() {
    my $ui = shift;
   
    my $cmd = join("",@_); 
    $cmd =~ s/\\n/\n/g;
    open (FOO,"|osascript") ;
    print FOO $cmd;
    close(FOO);
    $ui->print($output);
}
	  
command_r('applescript' => \&applescript_cmd);

shelp_r("applescript" => "Run arbitrary applescript");
help_r("applescript",  <<END
Usage: %applescript "applescript"

No, that's it. run arbitrary applescript.
END
);

1;