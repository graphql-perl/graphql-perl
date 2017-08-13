#!perl
use 5.014;
use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
  use_ok( 'GraphQL::Parser' ) || print "Bail out!\n";
}

lives_ok { do_parse(<<'EOF') } 'simple schema';
type Hello {
  world: String
}
EOF

sub do_parse {
  return GraphQL::Parser->parse($_[0]);
}

done_testing;
