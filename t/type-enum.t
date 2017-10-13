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
  use_ok( 'GraphQL::Introspection' ) || print "Bail out!\n";
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

subtest 'enum may be output type', sub {
  run_test(
    [$schema, '{ colorEnum(fromInt: 1) }'],
    { data => { colorEnum => 'GREEN' } },
  );
  done_testing;
};

subtest 'enum may be both input and output type', sub {
  run_test(
    [$schema, '{ colorEnum(fromEnum: GREEN) }'],
    { data => { colorEnum => 'GREEN' } },
  );
  done_testing;
};

subtest 'does not accept string literals', sub {
  run_test(
    [$schema, '{ colorEnum(fromEnum: "GREEN") }'],
    { data => { colorEnum => undef }, errors => [
      { message => "Argument 'fromEnum' of type 'Color' was given 'GREEN' which is not enum value.",
        locations => [ { line => 1, column => 32 } ],
    } ] },
  );
  done_testing;
};

subtest 'does not accept incorrect internal value', sub {
  run_test(
    [$schema, '{ colorEnum(fromString: "GREEN") }'],
    { data => { colorEnum => undef }, errors => [
      { message => "Expected a value of type 'Color' but received: 'GREEN'.\n",
        locations => [ { line => 1, column => 34 } ],
    } ] },
  );
  done_testing;
};

subtest 'does not accept internal value in place of enum literal', sub {
  run_test(
    [$schema, '{ colorEnum(fromEnum: 1) }'],
    { data => { colorEnum => undef }, errors => [
      { message => "Argument 'fromEnum' of type 'Color' was given '1' which is not enum value.",
        locations => [ { line => 1, column => 26 } ],
    } ] },
  );
  done_testing;
};

subtest 'does not accept enum literal in place of int', sub {
  run_test(
    [$schema, '{ colorEnum(fromInt: GREEN) }'],
    { data => { colorEnum => undef }, errors => [
      { message => "Argument 'fromInt' of type 'Int' was given GREEN which is enum value.",
        locations => [ { line => 1, column => 29 } ]
    } ] },
  );
  done_testing;
};

subtest 'accepts JSON string as enum variable', sub {
  run_test(
    [$schema, 'query test($color: Color!) { colorEnum(fromEnum: $color) }', undef, undef, { color => 'BLUE' }],
    { data => { colorEnum => 'BLUE' } },
  );
  done_testing;
};

subtest 'accepts enum literals as input arguments to mutations', sub {
  run_test(
    [$schema, 'mutation x($color: Color!) { favoriteEnum(color: $color) }', undef, undef, { color => 'GREEN' }],
    { data => { favoriteEnum => 'GREEN' } },
  );
  done_testing;
};

subtest 'accepts enum literals as input arguments to subscriptions', sub {
  run_test(
    [$schema, 'subscription x($color: Color!) { subscribeToEnum(color: $color) }', undef, undef, { color => 'GREEN' }],
    { data => { subscribeToEnum => 'GREEN' } },
  );
  done_testing;
};

subtest 'does not accept internal value as enum variable', sub {
  run_test(
    [$schema, 'query test($color: Color!) { colorEnum(fromEnum: $color) }', undef, undef, { color => 2 }],
    { errors => [
      { message => "Variable '\$color' got invalid value 2.\nExpected type 'Color', found 2.\n" }
    ] },
  );
  done_testing;
};

subtest 'does not accept string variables as enum input', sub {
  run_test(
    [$schema, 'query test($color: String!) { colorEnum(fromEnum: $color) }', undef, undef, { color => 'BLUE' }],
    { data => { colorEnum => undef }, errors => [
      { message => "Variable '\$color' of type 'String!' where expected 'Color'.",
        locations => [ { line => 1, column => 59 } ],
    } ] },
  );
  done_testing;
};

subtest 'does not accept internal value variable as enum input', sub {
  run_test(
    [$schema, 'query test($color: Int!) { colorEnum(fromEnum: $color) }', undef, undef, { color => 2 }],
    { data => { colorEnum => undef }, errors => [
      { message => "Variable '\$color' of type 'Int!' where expected 'Color'.",
        locations => [ { line => 1, column => 56 } ],
    } ] },
  );
  done_testing;
};

subtest 'enum value may have an internal value of 0', sub {
  run_test(
    [$schema, '{ colorEnum(fromEnum: RED) colorInt(fromEnum: RED) }'],
    { data => { colorEnum => 'RED', colorInt => 0 } },
  );
  done_testing;
};

subtest 'enum inputs may be nullable', sub {
  run_test(
    [$schema, '{ colorEnum colorInt }'],
    { data => { colorEnum => undef, colorInt => undef } },
  );
  done_testing;
};

subtest 'presents a getValues() API for complex enums', sub {
  is_deeply $ComplexEnum->_name2value, {
    ONE => $Complex1,
    TWO => $Complex2,
  };
  done_testing;
};

subtest 'may be internally represented with complex values', sub {
  run_test(
    [$schema, '{
      first: complexEnum
      second: complexEnum(fromEnum: TWO)
      good: complexEnum(provideGoodValue: true)
      bad: complexEnum(provideBadValue: true)
    }'],
    { data => {
      first => 'ONE',
      second => 'TWO',
      good => 'TWO',
      bad => undef,
    }, errors => [ {
      message => "Expected a value of type 'Complex' but received: HASH.\n",
      locations => [ { line => 6, column => 5 } ],
    } ] },
  );
  done_testing;
};

subtest 'can be introspected without error', sub {
  my $got = GraphQL::Execution->execute($schema, $GraphQL::Introspection::QUERY);
  local ($Data::Dumper::Sortkeys, $Data::Dumper::Indent, $Data::Dumper::Terse);
  $Data::Dumper::Sortkeys = $Data::Dumper::Indent = $Data::Dumper::Terse = 1;
  ok !$got->{errors}, 'no query errors' or diag Dumper $got;
  done_testing;
};

done_testing;
