use lib 't/lib';
use GQLTest;

my $JSON = JSON::MaybeXS->new->allow_nonref->canonical;

BEGIN {
  use_ok( 'GraphQL::Schema' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Execution', qw(execute) ) || print "Bail out!\n";
  use_ok( 'GraphQL::Language::Parser', qw(parse) ) || print "Bail out!\n";
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

subtest 'Input Object' => sub {
  my $doc = <<'EOF';
schema {
  query: Root
}

input Input {
  int: Int
}

type Root {
  field(in: Input): String
}
EOF
  is(GraphQL::Schema->from_doc($doc)->to_doc, $doc);
};

subtest 'Simple argument field with default' => sub {
  my $doc = <<'EOF';
schema {
  query: Hello
}

type Hello {
  str(int: Int = 2): String
}
EOF
  is(GraphQL::Schema->from_doc($doc)->to_doc, $doc);
};

subtest 'Simple type with mutation' => sub {
  my $doc = <<'EOF';
schema {
  query: HelloScalars
  mutation: Mutation
}

type HelloScalars {
  bool: Boolean
  int: Int
  str: String
}

type Mutation {
  addHelloScalars(bool: Boolean, int: Int, str: String): HelloScalars
}
EOF
  is(GraphQL::Schema->from_doc($doc)->to_doc, $doc);
};

# typo faithfully preserved
subtest 'Simple type with subscription' => sub {
  my $doc = <<'EOF';
schema {
  query: HelloScalars
  subscription: Subscription
}

type HelloScalars {
  bool: Boolean
  int: Int
  str: String
}

type Subscription {
  sbscribeHelloScalars(bool: Boolean, int: Int, str: String): HelloScalars
}
EOF
  is(GraphQL::Schema->from_doc($doc)->to_doc, $doc);
};

subtest 'Unreferenced type implementing referenced interface' => sub {
  my $doc = <<'EOF';
type Concrete implements Iface {
  key: String
}

interface Iface {
  key: String
}

type Query {
  iface: Iface
}
EOF
  is(GraphQL::Schema->from_doc($doc)->to_doc, $doc);
};

subtest 'Unreferenced type implementing referenced union' => sub {
  my $doc = <<'EOF';
type Concrete {
  key: String
}

type Query {
  union: Union
}

union Union = Concrete
EOF
  is(GraphQL::Schema->from_doc($doc)->to_doc, $doc);
};

subtest 'Supports @deprecated' => sub {
  my $doc = <<'EOF';
enum MyEnum {
  OLD_VALUE @deprecated
  OTHER_VALUE @deprecated(reason: "Terrible reasons")
  VALUE
}

type Query {
  enum: MyEnum
  field1: String @deprecated
  field2: Int @deprecated(reason: "Because I said so")
}
EOF
  is(GraphQL::Schema->from_doc($doc)->to_doc, $doc);
};

# except it doesn't - just round-trip
subtest 'Correctly assign AST nodes' => sub {
  my $doc = <<'EOF';
directive @test(arg: Int) on FIELD

type Query {
  testField(testArg: TestInput): TestUnion
}

enum TestEnum {
  TEST_VALUE
}

input TestInput {
  testInputField: TestEnum
}

interface TestInterface {
  interfaceField: String
}

type TestType implements TestInterface {
  interfaceField: String
}

union TestUnion = TestType
EOF
  is(GraphQL::Schema->from_doc($doc)->to_doc, $doc);
};

subtest 'Requires a schema definition or Query type' => sub {
  throws_ok { GraphQL::Schema->from_doc(<<'EOF') } qr/Must provide schema definition with query type or a type named Query./;
type Hello {
  bar: Bar
}
EOF
};

subtest 'Allows only a single schema definition' => sub {
  throws_ok { GraphQL::Schema->from_doc(<<'EOF') } qr/Must provide only one schema definition./;
schema { query: Hello }
schema { query: Hello }
type Hello { bar: Bar }
EOF
};

subtest 'Requires a query type' => sub {
  throws_ok { GraphQL::Schema->from_doc(<<'EOF') } qr/Must provide schema definition with query type or a type named Query./;
schema { mutation: Hello }
type Hello { bar: Bar }
EOF
};

subtest 'Allows only a single query type' => sub {
  throws_ok { GraphQL::Schema->from_doc(<<'EOF') } qr/Must provide only one query type in schema/;
schema { query: Hello query: Yellow }
type Hello { bar: Bar }
type Yellow { isColor: Boolean }
EOF
};

subtest 'Allows only a single mutation type' => sub {
  throws_ok { GraphQL::Schema->from_doc(<<'EOF') } qr/Must provide only one mutation type in schema/;
schema { query: Query mutation: Hello mutation: Yellow }
type Hello { bar: Bar }
type Yellow { isColor: Boolean }
EOF
};

subtest 'Allows only a single subscription type' => sub {
  throws_ok { GraphQL::Schema->from_doc(<<'EOF') } qr/Must provide only one subscription type in schema/;
schema { query: Query subscription: Hello subscription: Yellow }
type Hello { bar: Bar }
type Yellow { isColor: Boolean }
EOF
};

subtest 'Unknown type referenced' => sub {
  throws_ok { GraphQL::Schema->from_doc(<<'EOF') } qr/Unknown type 'Bar'/;
schema { query: Hello }
type Hello { bar: Bar }
EOF
};

subtest 'Unknown type in interface list' => sub {
  throws_ok { GraphQL::Schema->from_doc(<<'EOF') } qr/Unknown type 'Bar'/;
schema { query: Hello }
type Hello implements Bar { bar: String }
EOF
};

subtest 'Unknown type in union list' => sub {
  throws_ok { GraphQL::Schema->from_doc(<<'EOF') } qr/Unknown type 'Bar'/;
schema { query: Hello }
union TestUnion = Bar
type Hello { testUnion: TestUnion }
EOF
};

subtest 'Unknown query type' => sub {
  throws_ok { GraphQL::Schema->from_doc(<<'EOF') } qr/Specified query type 'Wat' not found/;
schema { query: Wat }
type Hello { str: String }
EOF
};

subtest 'Unknown mutation|subscription type' => sub {
  throws_ok { GraphQL::Schema->from_doc(<<EOF) } qr/Specified $_ type 'Wat' not found/ for qw(mutation subscription);
schema { query: Hello $_: Wat }
type Hello { str: String }
EOF
};

subtest 'Does not consider operation names' => sub {
  throws_ok { GraphQL::Schema->from_doc(<<'EOF') } qr/Specified query type 'Foo' not found/;
schema { query: Foo }
query Foo { field }
EOF
};

subtest 'Does not consider fragment names' => sub {
  throws_ok { GraphQL::Schema->from_doc(<<'EOF') } qr/Specified query type 'Foo' not found/;
schema { query: Foo }
fragment Foo on Type { field }
EOF
};

subtest 'Forbids duplicate type definitions' => sub {
  throws_ok { GraphQL::Schema->from_doc(<<'EOF') } qr/Type 'Repeated' was defined more than once/;
schema { query: Repeated }
type Repeated { id: Int }
type Repeated { id: String }
EOF
};

done_testing;
