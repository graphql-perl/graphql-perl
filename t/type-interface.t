use 5.014;
use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
  use_ok( 'GraphQL::Type::Interface' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Scalar', qw($String) ) || print "Bail out!\n";
}

my $interface_type = GraphQL::Type::Interface->new(
  name => 'Interface',
  fields => { field_name => { type => $String } },
  resolve_type => sub {
    return $String;
  },
);

throws_ok {
  GraphQL::Type::Interface->new(
    name => '@Interface',
    fields => { field_name => { type => $String } },
  )
} qr/did not pass type constraint/, 'name validation';

done_testing;
