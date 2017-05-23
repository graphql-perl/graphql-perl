#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
  use_ok( 'GraphQL::Language' ) || print "Bail out!\n";
}

my $implementingType;
my $interfaceType = GraphQL::Language->parse(
  '{',
);

done_testing;
