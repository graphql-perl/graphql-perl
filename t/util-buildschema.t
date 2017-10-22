use 5.014;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Deep;
use JSON::MaybeXS;
use Data::Dumper;

my $JSON = JSON::MaybeXS->new->allow_nonref->canonical;

BEGIN {
  use_ok( 'GraphQL::Schema' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Execution', qw(execute) ) || print "Bail out!\n";
  use_ok( 'GraphQL::Language::Parser', qw(parse) ) || print "Bail out!\n";
}

sub run_test {
  my ($args, $expected) = @_;
  my $got = execute(@$args);
  is_deeply $got, $expected or diag nice_dump($got);
}

sub nice_dump {
  my ($got) = @_;
  local ($Data::Dumper::Sortkeys, $Data::Dumper::Indent, $Data::Dumper::Terse);
  $Data::Dumper::Sortkeys = $Data::Dumper::Indent = $Data::Dumper::Terse = 1;
  Dumper $got;
}

subtest 'can use built schema for limited execution' => sub {
  my $ast = parse(<<'EOF');
schema { query: Query }
type Query {
  str: String
}
EOF
  my $schema = GraphQL::Schema->from_ast($ast);
  run_test(
    [$schema, '{ str }', { str => 123 }],
    { data => { str => '123' } },
  );
};

subtest 'can build a schema directly from the source' => sub {
  my $doc = <<'EOF';
schema { query: Query }
type Query {
  add(x: Int, y: Int): Int
}
EOF
  my $schema = GraphQL::Schema->from_doc($doc);
  run_test(
    [$schema, '{ add(x: 34, y: 55) }', {add => sub {$_[0]->{x} + $_[0]->{y}}}],
    { data => { add => 89 } },
  );
};

subtest 'Simple type' => sub {
  my $doc = <<'EOF';
schema {
  query: HelloScalars
}

type HelloScalars {
  bool: Boolean
  float: Float
  id: ID
  int: Int
  str: String
}
EOF
  is(GraphQL::Schema->from_doc($doc)->to_doc, $doc);
};

subtest 'With directives' => sub {
  my $doc = <<'EOF';
schema {
  query: Hello
}

directive @foo(arg: Int) on FIELD

type Hello {
  str: String
}
EOF
  is(GraphQL::Schema->from_doc($doc)->to_doc, $doc);
};

subtest 'Supports descriptions' => sub {
  my $doc = <<'EOF';
schema {
  query: Hello
}

# This is a directive
directive @foo(
  # It has an argument
  arg: Int
) on FIELD

# With an enum
enum Color {
  BLUE
  # Not a creative color
  GREEN
  RED
}

# What a great type
type Hello {
  # And a field to boot
  str: String
}
EOF
  is(GraphQL::Schema->from_doc($doc)->to_doc, $doc);
};

subtest 'Maintains @skip & @include' => sub {
  my $doc = <<'EOF';
schema {
  query: Hello
}
type Hello {
  str: String
}
EOF
  my $schema = GraphQL::Schema->from_doc($doc);
  is_deeply $schema->directives, \@GraphQL::Directive::SPECIFIED_DIRECTIVES;
};

subtest 'Overriding directives excludes specified' => sub {
  my $doc = <<'EOF';
schema {
  query: Hello
}
directive @skip on FIELD
directive @include on FIELD
directive @deprecated on FIELD_DEFINITION
type Hello {
  str: String
}
EOF
  my $schema = GraphQL::Schema->from_doc($doc);
  is keys %{ $schema->name2directive }, 3;
  isnt $schema->name2directive->{skip}, $GraphQL::Directive::SKIP;
  isnt $schema->name2directive->{include}, $GraphQL::Directive::INCLUDE;
  isnt $schema->name2directive->{deprecated}, $GraphQL::Directive::DEPRECATED;
};

subtest 'Adding directives maintains @skip & @include' => sub {
  my $doc = <<'EOF';
schema {
  query: Hello
}
directive @foo(arg: Int) on FIELD
type Hello {
  str: String
}
EOF
  my $schema = GraphQL::Schema->from_doc($doc);
  is keys %{ $schema->name2directive }, 4;
  is $schema->name2directive->{skip}, $GraphQL::Directive::SKIP;
  is $schema->name2directive->{include}, $GraphQL::Directive::INCLUDE;
  is $schema->name2directive->{deprecated}, $GraphQL::Directive::DEPRECATED;
};

subtest 'Type modifiers' => sub {
  my $doc = <<'EOF';
schema {
  query: HelloScalars
}

type HelloScalars {
  listOfNonNullStrs: [String!]
  listOfStrs: [String]
  nonNullListOfNonNullStrs: [String!]!
  nonNullListOfStrs: [String]!
  nonNullStr: String!
}
EOF
  is(GraphQL::Schema->from_doc($doc)->to_doc, $doc);
};

subtest 'Recursive type' => sub {
  my $doc = <<'EOF';
schema {
  query: Recurse
}

type Recurse {
  recurse: Recurse
  str: String
}
EOF
  is(GraphQL::Schema->from_doc($doc)->to_doc, $doc);
};

subtest 'Two types circular' => sub {
  my $doc = <<'EOF';
schema {
  query: TypeOne
}

type TypeOne {
  str: String
  typeTwo: TypeTwo
}

type TypeTwo {
  str: String
  typeOne: TypeOne
}
EOF
  is(GraphQL::Schema->from_doc($doc)->to_doc, $doc);
};

subtest 'Single argument field' => sub {
  my $doc = <<'EOF';
schema {
  query: Hello
}

type Hello {
  booleanToStr(bool: Boolean): String
  floatToStr(float: Float): String
  idToStr(id: ID): String
  str(int: Int): String
  strToStr(bool: String): String
}
EOF
  is(GraphQL::Schema->from_doc($doc)->to_doc, $doc);
};

subtest 'Simple type with multiple arguments' => sub {
  my $doc = <<'EOF';
schema {
  query: Hello
}

type Hello {
  str(bool: Boolean, int: Int): String
}
EOF
  is(GraphQL::Schema->from_doc($doc)->to_doc, $doc);
};

subtest 'Simple type with interface' => sub {
  my $doc = <<'EOF';
schema {
  query: Hello
}

type Hello implements WorldInterface {
  str: String
}

interface WorldInterface {
  str: String
}
EOF
  is(GraphQL::Schema->from_doc($doc)->to_doc, $doc);
};

subtest 'Simple output enum' => sub {
  my $doc = <<'EOF';
schema {
  query: OutputEnumRoot
}

enum Hello {
  WORLD
}

type OutputEnumRoot {
  hello: Hello
}
EOF
  is(GraphQL::Schema->from_doc($doc)->to_doc, $doc);
};

subtest 'Simple input enum' => sub {
  my $doc = <<'EOF';
schema {
  query: InputEnumRoot
}

enum Hello {
  WORLD
}

type InputEnumRoot {
  str(hello: Hello): String
}
EOF
  is(GraphQL::Schema->from_doc($doc)->to_doc, $doc);
};

subtest 'Multiple value enum' => sub {
  my $doc = <<'EOF';
schema {
  query: OutputEnumRoot
}

enum Hello {
  RLD
  WO
}

type OutputEnumRoot {
  hello: Hello
}
EOF
  is(GraphQL::Schema->from_doc($doc)->to_doc, $doc);
};

subtest 'Simple Union' => sub {
  my $doc = <<'EOF';
schema {
  query: Root
}

union Hello = World

type Root {
  hello: Hello
}

type World {
  str: String
}
EOF
  is(GraphQL::Schema->from_doc($doc)->to_doc, $doc);
};

subtest 'Multiple Union' => sub {
  my $doc = <<'EOF';
schema {
  query: Root
}

union Hello = WorldOne | WorldTwo

type Root {
  hello: Hello
}

type WorldOne {
  str: String
}

type WorldTwo {
  str: String
}
EOF
  is(GraphQL::Schema->from_doc($doc)->to_doc, $doc);
};

subtest 'Custom Scalar' => sub {
  my $doc = <<'EOF';
schema {
  query: Root
}

scalar CustomScalar

type Root {
  customScalar: CustomScalar
}
EOF
  is(GraphQL::Schema->from_doc($doc)->to_doc, $doc);
};

done_testing;
