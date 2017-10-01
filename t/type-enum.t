#!perl -T
use 5.014;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Data::Dumper;

BEGIN {
  use_ok( 'GraphQL::Schema' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Enum' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Object' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Scalar', qw($String $Int $Boolean) ) || print "Bail out!\n";
  use_ok( 'GraphQL::Execution' ) || print "Bail out!\n";
}

my $ColorType = GraphQL::Type::Enum->new(
  name => 'Color',
  values => {
    RED => { value => 0 },
    GREEN => { value => 1 },
    BLUE => { value => 2 },
  },
);

my $Complex1 = { someRandomFunction => sub { } };
my $Complex2 = { someRandomValue => 123 };

my $ComplexEnum = GraphQL::Type::Enum->new(
  name => 'Complex',
  values => {
    ONE => { value => $Complex1 },
    TWO => { value => $Complex2 },
  },
);

my $QueryType = GraphQL::Type::Object->new(
  name => 'Query',
  fields => {
    colorEnum => {
      type => $ColorType,
      args => {
        fromEnum => { type => $ColorType },
        fromInt => { type => $Int },
        fromString => { type => $String },
      },
      resolve => sub {
        $_[1]->{fromInt} // $_[1]->{fromString} // $_[1]->{fromEnum};
      },
    },
    colorInt => {
      type => $Int,
      args => {
        fromEnum => { type => $ColorType },
        fromInt => { type => $Int },
      },
      resolve => sub {
        $_[1]->{fromInt} // $_[1]->{fromEnum};
      },
    },
    complexEnum => {
      type => $ComplexEnum,
      args => {
        fromEnum => {
          type => $ComplexEnum,
          default_value => $Complex1, # internal not JSON
        },
        provideGoodValue => { type => $Boolean },
        provideBadValue => { type => $Boolean },
      },
      resolve => sub {
        return $Complex2 if $_[1]->{provideGoodValue};
        return { %$Complex2 } if $_[1]->{provideBadValue}; # copy so not ==
        $_[1]->{fromEnum};
      },
    },
  }
);

my $MutationType = GraphQL::Type::Object->new(
  name => 'Mutation',
  fields => {
    favoriteEnum => {
      type => $ColorType,
      args => { color => { type => $ColorType } },
      resolve => sub { $_[1]->{color} },
    },
  },
);

my $SubscriptionType = GraphQL::Type::Object->new(
  name => 'Subscription',
  fields => {
    subscribeToEnum => {
      type => $ColorType,
      args => { color => { type => $ColorType } },
      resolve => sub { $_[1]->{color} },
    },
  },
);

my $schema = GraphQL::Schema->new(
  query => $QueryType,
  mutation => $MutationType,
  subscription => $SubscriptionType,
);

sub run_test {
  my ($args, $expected) = @_;
  my $got = GraphQL::Execution->execute(@$args);
  local ($Data::Dumper::Sortkeys, $Data::Dumper::Indent, $Data::Dumper::Terse);
  $Data::Dumper::Sortkeys = $Data::Dumper::Indent = $Data::Dumper::Terse = 1;
  is_deeply $got, $expected or diag Dumper $got;
}

subtest 'accepts enum literals as input', sub {
  run_test(
    [$schema, '{ colorInt(fromEnum: GREEN) }'],
    { data => { colorInt => 1 } },
  );
  done_testing;
};

done_testing;
