#!perl -T
use 5.014;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use JSON::MaybeXS;
use Data::Dumper;

BEGIN {
  use_ok( 'GraphQL::Schema' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Object' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Interface' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Union' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Scalar', qw($String $Boolean) ) || print "Bail out!\n";
  use_ok( 'GraphQL::Execution' ) || print "Bail out!\n";
}

{
  package Dog;
  use Moo;
  has [qw(name woofs)] => (is => 'ro');
}

{
  package Cat;
  use Moo;
  has [qw(name meows)] => (is => 'ro');
}

{
  package Human;
  use Moo;
  has name => (is => 'ro');
}

my @PETOBJS = (Dog->new(name => 'Odie', woofs => 1), Cat->new(name => 'Garfield', meows => 0));
my $DOC = '{
  pets {
    name
    ... on Dog {
      woofs
    }
    ... on Cat {
      meows
    }
  }
}';
my @EXPECTED = (
  { name => 'Odie', woofs => JSON->true },
  { name => 'Garfield', meows => JSON->false },
);

sub make_schema {
  my ($pets_type, $resolve, $other_args) = @_;
  GraphQL::Schema->new(
    query => GraphQL::Type::Object->new(
      name => 'Query',
      fields => {
        pets => {
          type => $pets_type,
          resolve => $resolve,
        },
      },
    ),
    @{ $other_args || [] },
  );
}

sub run_test {
  my ($args, $expected) = @_;
  my $got = GraphQL::Execution->execute(@$args);
  local ($Data::Dumper::Sortkeys, $Data::Dumper::Indent, $Data::Dumper::Terse);
  $Data::Dumper::Sortkeys = $Data::Dumper::Indent = $Data::Dumper::Terse = 1;
  is_deeply $got, $expected or diag Dumper $got;
}

# makes field-resolver that takes resolver args and calls Moo accessor, returns field_def
sub make_field {
  my ($field_name, $type) = @_;
  ($field_name => { resolve => sub {
    my ($root_value, $args, $context, $info) = @_;
    my @passon = %$args ? ($args) : ();
    $root_value->$field_name(@passon);
  }, type => $type });
}

subtest 'isTypeOf used to resolve runtime type for Interface', sub {
  my $PetType = GraphQL::Type::Interface->new(
    name => 'Pet',
    fields => { name => { type => $String } },
  );
  my $DogType = GraphQL::Type::Object->new(
    name => 'Dog',
    interfaces => [ $PetType ],
    is_type_of => sub { $_[0]->isa('Dog') },
    fields => { make_field(name => $String), make_field(woofs => $Boolean) },
  );
  my $CatType = GraphQL::Type::Object->new(
    name => 'Cat',
    interfaces => [ $PetType ],
    is_type_of => sub { $_[0]->isa('Cat') },
    fields => { make_field(name => $String), make_field(meows => $Boolean) },
  );
  my $schema = make_schema(
    $PetType->list,
    sub { [ @PETOBJS ] },
    [ types => [ $CatType, $DogType ] ],
  );
  run_test(
    [$schema, $DOC],
    { data => {
      pets => [ @EXPECTED ],
    } },
  );
  done_testing;
};

subtest 'isTypeOf used to resolve runtime type for Union', sub {
  my $DogType = GraphQL::Type::Object->new(
    name => 'Dog',
    is_type_of => sub { $_[0]->isa('Dog') },
    fields => { make_field(name => $String), make_field(woofs => $Boolean) },
  );
  my $CatType = GraphQL::Type::Object->new(
    name => 'Cat',
    is_type_of => sub { $_[0]->isa('Cat') },
    fields => { make_field(name => $String), make_field(meows => $Boolean) },
  );
  my $PetType = GraphQL::Type::Union->new(
    name => 'Pet',
    types => [ $DogType, $CatType ],
  );
  my $schema = make_schema(
    $PetType->list,
    sub { [ @PETOBJS ] },
  );
  run_test(
    [$schema, $DOC],
    { data => {
      pets => [ @EXPECTED ],
    } },
  );
  done_testing;
};

subtest 'resolveType on Interface yields useful error', sub {
  my ($CatType, $DogType, $HumanType);
  my $PetType = GraphQL::Type::Interface->new(
    name => 'Pet',
    fields => { name => { type => $String } },
    resolve_type => sub {
      $_[0]->isa('Dog') ? $DogType :
      $_[0]->isa('Cat') ? $CatType :
      $_[0]->isa('Human') ? $HumanType :
      undef
    },
  );
  $HumanType = GraphQL::Type::Object->new(
    name => 'Human',
    fields => { make_field(name => $String) },
  );
  $DogType = GraphQL::Type::Object->new(
    name => 'Dog',
    interfaces => [ $PetType ],
    fields => { make_field(name => $String), make_field(woofs => $Boolean) },
  );
  $CatType = GraphQL::Type::Object->new(
    name => 'Cat',
    interfaces => [ $PetType ],
    fields => { make_field(name => $String), make_field(meows => $Boolean) },
  );
  my $schema = make_schema(
    $PetType->list,
    sub { [ @PETOBJS, Human->new(name => 'Jon') ] },
    [ types => [ $CatType, $DogType ] ],
  );
  run_test(
    [$schema, $DOC],
    { data => {
      pets => [ @EXPECTED, undef ],
    }, errors => [
      { message => "Runtime Object type 'Human' is not a possible type for 'Pet'." },
    ] },
  );
  done_testing;
};

subtest 'resolveType on Union yields useful error', sub {
  my ($CatType, $DogType, $HumanType);
  $HumanType = GraphQL::Type::Object->new(
    name => 'Human',
    fields => { make_field(name => $String) },
  );
  $DogType = GraphQL::Type::Object->new(
    name => 'Dog',
    fields => { make_field(name => $String), make_field(woofs => $Boolean) },
  );
  $CatType = GraphQL::Type::Object->new(
    name => 'Cat',
    fields => { make_field(name => $String), make_field(meows => $Boolean) },
  );
  my $PetType = GraphQL::Type::Union->new(
    name => 'Pet',
    resolve_type => sub {
      $_[0]->isa('Dog') ? $DogType :
      $_[0]->isa('Cat') ? $CatType :
      $_[0]->isa('Human') ? $HumanType :
      undef
    },
    types => [ $DogType, $CatType ],
  );
  my $schema = make_schema(
    $PetType->list,
    sub { [ @PETOBJS, Human->new(name => 'Jon') ] },
  );
  run_test(
    [$schema, $DOC],
    { data => {
      pets => [ @EXPECTED, undef ],
    }, errors => [
      { message => "Runtime Object type 'Human' is not a possible type for 'Pet'." },
    ] },
  );
  done_testing;
};

subtest 'resolveType allows resolving with type name', sub {
  my ($CatType, $DogType, $HumanType);
  my $PetType = GraphQL::Type::Interface->new(
    name => 'Pet',
    fields => { name => { type => $String } },
    resolve_type => sub {
      $_[0]->isa('Dog') ? 'Dog' :
      $_[0]->isa('Cat') ? 'Cat' :
      undef
    },
  );
  $DogType = GraphQL::Type::Object->new(
    name => 'Dog',
    interfaces => [ $PetType ],
    fields => { make_field(name => $String), make_field(woofs => $Boolean) },
  );
  $CatType = GraphQL::Type::Object->new(
    name => 'Cat',
    interfaces => [ $PetType ],
    fields => { make_field(name => $String), make_field(meows => $Boolean) },
  );
  my $schema = make_schema(
    $PetType->list,
    sub { [ @PETOBJS ] },
    [ types => [ $CatType, $DogType ] ],
  );
  run_test(
    [$schema, $DOC],
    { data => {
      pets => [ @EXPECTED ],
    } },
  );
  done_testing;
};

done_testing;
