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

throws_ok { do_parse(<<'EOF'
{ ...MissingOn }
fragment MissingOn Type
EOF
) } qr/Expected "on"/, 'missing "on"';

throws_ok { do_parse('{ field: {} }') } qr/Expected name/, 'expected';
throws_ok { do_parse('notanoperation Foo { field }') } qr/Parse document failed/, 'bad op';
throws_ok { do_parse('...') } qr/Parse document failed/, 'spread wrong place';

sub do_parse {
  return GraphQL::Parser->parse($_[0]);
}

done_testing;
