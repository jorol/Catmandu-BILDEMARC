#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Catmandu::BILDEMARC' ) || print "Bail out!\n";
}

diag( "Testing Catmandu::BILDEMARC $Catmandu::BILDEMARC::VERSION, Perl $], $^X" );
