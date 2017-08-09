#!perl -T
use 5.014;
use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
  use_ok( 'GraphQL::Parser' ) || print "Bail out!\n";
}

throws_ok { do_parse('{') } qr/Expected name/, 'trivial fail';

sub do_parse {
  return GraphQL::Parser->parse($_[0]);
}

done_testing;
