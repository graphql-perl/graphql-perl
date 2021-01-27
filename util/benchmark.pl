use strict;
use warnings;

use lib './lib';

use Benchmark;

use GraphQL::Schema;
use GraphQL::Type::Object;
use GraphQL::Type::Scalar qw($String $Int $Boolean);
use GraphQL::Execution qw(execute);
use GraphQL::Language::Parser qw(parse);

###########
# Prep schema
my ($deep_data, $data);
$data = {
  a   => sub {'Apple'},
  b   => sub {'Banana'},
  c   => sub {'Cookie'},
  d   => sub {'Donut'},
  e   => sub {'Egg'},
  f   => 'Fish',
  pic => sub {
    my $size = shift;
    return 'Pic of size: ' . ($size || 50);
  },
  deep    => sub {$deep_data},
  promise => sub { FakePromise->resolve($data) },
};

$deep_data = {
  a      => sub {'Already Been Done'},
  b      => sub {'Boring'},
  c      => sub { [ 'Contrived', undef, 'Confusing' ] },
  deeper => sub { [ $data, undef, $data ] }
};

my ($DeepDataType, $DataType);
$DataType = GraphQL::Type::Object->new(
  name   => 'DataType',
  fields => sub {
    {
      a   => {type => $String},
      b   => {type => $String},
      c   => {type => $String},
      d   => {type => $String},
      e   => {type => $String},
      f   => {type => $String},
      pic => {
        args    => {size => {type => $Int}},
        type    => $String,
        resolve => sub {
          my ($obj, $args) = @_;
          return $obj->{pic}->($args->{size});
        }
      },
      deep    => {type => $DeepDataType},
      promise => {type => $DataType},
    }
  }
);

$DeepDataType = GraphQL::Type::Object->new(
  name   => 'DeepDataType',
  fields => {
    a      => {type => $String},
    b      => {type => $String},
    c      => {type => $String->list},
    deeper => {type => $DataType->list},
  }
);

my $schema = GraphQL::Schema->new(query => $DataType);

my $doc = <<'EOF';
query Example($size: Int) {
  a,
  b,
  x: c
  ...c
  f
  ...on DataType {
    pic(size: $size)
    promise {
      a
    }
  }
  deep {
    a
    b
    c
    deeper {
      a
      b
    }
  }
}
fragment c on DataType {
  d
  e
}
EOF
my $ast = parse($doc);

timethis(-5, sub { execute($schema, $ast, $data, undef, {size => 100}, 'Example') });
