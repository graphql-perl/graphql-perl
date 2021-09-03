use 5.014;
use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
  use_ok( 'GraphQL::Plugin::Type::DateTime' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Interface' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Object' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Enum' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Union' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::InputObject' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Schema' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Scalar', qw($String $Int $Boolean) ) || print "Bail out!\n";
}

my $BlogImage = GraphQL::Type::Object->new(
  name => 'Image',
  fields => {
    url => { type => $String },
    width => { type => $Int },
    height => { type => $Int },
  },
);

my $BlogArticle;
my $BlogAuthor = GraphQL::Type::Object->new(
  name => 'Author',
  fields => sub { {
    id => { type => $String },
    name => { type => $String },
    pic => {
      args => { width => { type => $Int }, height => { type => $Int } },
      type => $BlogImage,
    },
    recentArticle => { type => $BlogArticle },
  } },
);

$BlogArticle = GraphQL::Type::Object->new(
  name => 'Article',
  fields => {
    id => { type => $String },
    isPublished => { type => $Boolean },
    author => { type => $BlogAuthor },
    title => { type => $String },
    body => { type => $String },
  },
);

my $BlogQuery = GraphQL::Type::Object->new(
  name => 'Query',
  fields => {
    article => {
      args => { width => { type => $Int }, height => { type => $Int } },
      type => $BlogArticle,
    },
    feed => { type => $BlogArticle->list },
  },
);

my $BlogMutation = GraphQL::Type::Object->new(
  name => 'Mutation',
  fields => {
    writeArticle => {
      type => $BlogArticle,
    },
  },
);

my $BlogSubscription = GraphQL::Type::Object->new(
  name => 'Subscription',
  fields => {
    articleSubscribe => {
      args => { id => { type => $String } },
      type => $BlogArticle,
    },
  },
);

my $ObjectType = GraphQL::Type::Object->new(
  name => 'Object',
  is_type_of => sub { 1 },
  fields => {},
);
my $InterfaceType = GraphQL::Type::Interface->new(
  name => 'Interface',
  is_type_of => sub { 1 },
  fields => {},
);
my $UnionType = GraphQL::Type::Union->new(
  name => 'Union',
  types => [ $ObjectType ],
);
my $EnumType = GraphQL::Type::Enum->new(
  name => 'Enum',
  values => { foo => {} },
);
my $InputObjectType = GraphQL::Type::InputObject->new(name => 'InputObject', fields => {});

subtest 'Type System: Example', sub {
  my $schema = GraphQL::Schema->new(query => $BlogQuery);
  is $schema->query, $BlogQuery;
  my $article_field = $BlogQuery->fields->{article};
  my $article_field_type = $article_field->{type};
  is $article_field_type, $BlogArticle;
  is $article_field_type->name, 'Article';
  my $title_field = $article_field_type->fields->{title};
  is $title_field->{type}, $String;
  is $title_field->{type}->name, 'String';
  my $author_field = $article_field_type->fields->{author};
  my $author_field_type = $author_field->{type};
  my $recent_article_field = $author_field_type->fields->{recentArticle};
  is $recent_article_field->{type}, $BlogArticle;
  my $feed_field = $BlogQuery->fields->{feed};
  is $feed_field->{type}->of, $BlogArticle;
};

subtest 'defines a mutation schema', sub {
  my $schema = GraphQL::Schema->new(query => $BlogQuery, mutation => $BlogMutation);
  is $schema->mutation, $BlogMutation;
  my $write_mutation = $BlogMutation->fields->{writeArticle};
  is $write_mutation->{type}, $BlogArticle;
  is $write_mutation->{type}->name, 'Article';
};

subtest 'defines a subscription schema', sub {
  my $schema = GraphQL::Schema->new(query => $BlogQuery, subscription => $BlogSubscription);
  is $schema->subscription, $BlogSubscription;
  my $sub = $BlogSubscription->fields->{articleSubscribe};
  is $sub->{type}, $BlogArticle;
  is $sub->{type}->name, 'Article';
};

subtest 'defines an enum type with deprecated value', sub {
  my $EnumTypeWithDeprecatedValue = GraphQL::Type::Enum->new(
    name => 'EnumTypeWithDeprecatedValue',
    values => { foo => { deprecation_reason => 'Just because' } },
  );
  is_deeply $EnumTypeWithDeprecatedValue->values, {
    foo => {
      deprecation_reason => 'Just because',
      is_deprecated => 1,
      value => 'foo',
    },
  };
};

subtest 'defines an enum type with a value of `undef`', sub {
  # var name from JS test, but Perl has no null only undef
  my $EnumTypeWithNullishValue = GraphQL::Type::Enum->new(
    name => 'EnumTypeWithNullishValue',
    values => {
      foo => {},
      UNDEFINED => { value => undef },
    },
  );
  is_deeply $EnumTypeWithNullishValue->values, {
    foo => {
      value => 'foo',
    },
    UNDEFINED => {
      value => undef,
    },
  };
};

subtest 'defines an object type with deprecated field', sub {
  my $TypeWithDeprecatedField = GraphQL::Type::Object->new(
    name => 'foo',
    fields => {
      bar => { type => $String, deprecation_reason => 'A terrible reason' },
    },
  );
  is_deeply $TypeWithDeprecatedField->fields, {
    bar => {
      type => $String,
      deprecation_reason => 'A terrible reason',
      is_deprecated => 1,
    },
  };
};

subtest 'define definitions including fields with directives', sub {
  my $TypeWithFieldWithDirective = GraphQL::Type::Object->new(
    name => 'foo',
    fields => {
      bar => {
        type => $String,
        directives => [
          {
            name => 'directive',
            arguments => { arg => 'value' },
          }
        ]
      }
    },
  );
  is_deeply $TypeWithFieldWithDirective->fields->{bar}->{directives}, [
    {
      name => 'directive',
      arguments => { arg => 'value' },
    }
  ];

  my $InterfaceWithFieldWithDirective = GraphQL::Type::Interface->new(
    name => 'foo',
    fields => {
      bar => {
        type => $String,
        directives => [
          {
            name => 'directive',
            arguments => { arg => 'value' },
          }
        ]
      }
    },
  );
  is_deeply $InterfaceWithFieldWithDirective->fields->{bar}->{directives}, [
    {
      name => 'directive',
      arguments => { arg => 'value' },
    }
  ];

  my $InputWithFieldWithDirective = GraphQL::Type::InputObject->new(
    name => 'foo',
    fields => {
      bar => {
        type => $String,
        directives => [
          {
            name => 'directive',
            arguments => { arg => 'value' },
          }
        ]
      }
    },
  );
  is_deeply $InputWithFieldWithDirective->fields->{bar}->{directives}, [
    {
      name => 'directive',
      arguments => { arg => 'value' },
    }
  ];
};

subtest 'includes nested input objects in the map', sub {
  my $NestedInputObject = GraphQL::Type::InputObject->new(
    name => 'NestedInputObject',
    fields => { value => { type => $String } },
  );
  my $SomeInputObject = GraphQL::Type::InputObject->new(
    name => 'SomeInputObject',
    fields => { nested => { type => $NestedInputObject } },
  );
  my $SomeMutation = GraphQL::Type::Object->new(
    name => 'SomeMutation',
    fields => {
      mutateSomething => {
        type => $BlogArticle,
        args => { input => { type => $SomeInputObject } },
      },
    },
  );
  my $SomeSubscription = GraphQL::Type::Object->new(
    name => 'SomeSubscription',
    fields => {
      subscribeToSomething => {
        type => $BlogArticle,
        args => { input => { type => $SomeInputObject } },
      },
    },
  );
  my $schema = GraphQL::Schema->new(
    query => $BlogQuery,
    mutation => $SomeMutation,
    subscription => $SomeSubscription,
  );
  is_deeply [ sort keys %{$schema->name2type} ], [
    qw(Article Author Boolean DateTime Float ID Image Int NestedInputObject Query SomeInputObject SomeMutation SomeSubscription String),
    qw(__Directive __DirectiveLocation __EnumValue __Field __InputValue __Schema __Type __TypeKind)
  ] or diag explain [ sort keys %{$schema->name2type} ];
};

subtest 'includes interfaces\' subtypes in the type map', sub {
  my $SomeInterface = GraphQL::Type::Interface->new(
    name => 'SomeInterface',
    fields => { f => { type => $Int } },
  );
  my $SomeSubtype = GraphQL::Type::Object->new(
    name => 'SomeSubtype',
    fields => { f => { type => $Int } },
    interfaces => [ $SomeInterface ],
    is_type_of => sub { 1 },
  );
  my $query = GraphQL::Type::Object->new(
    name => 'Query',
    fields => { iface => { type => $SomeInterface } },
  );
  my $schema = GraphQL::Schema->new(query => $query, types => [ $SomeSubtype ]);
  is_deeply [ sort keys %{$schema->name2type} ], [
    qw(Boolean Int Query SomeInterface SomeSubtype String),
    qw(__Directive __DirectiveLocation __EnumValue __Field __InputValue __Schema __Type __TypeKind)
  ] or diag explain [ sort keys %{$schema->name2type} ];
};

subtest 'includes interfaces\' thunk subtypes in the type map', sub {
  my $SomeInterface = GraphQL::Type::Interface->new(
    name => 'SomeInterface',
    fields => { f => { type => $Int } },
  );
  my $SomeSubtype = GraphQL::Type::Object->new(
    name => 'SomeSubtype',
    fields => { f => { type => $Int } },
    interfaces => sub { [ $SomeInterface ] },
    is_type_of => sub { 1 },
  );
  my $query = GraphQL::Type::Object->new(
    name => 'Query',
    fields => { iface => { type => $SomeInterface } },
  );
  my $schema = GraphQL::Schema->new(query => $query, types => [ $SomeSubtype ]);
  is_deeply [ sort keys %{$schema->name2type} ], [
    qw(Boolean Int Query SomeInterface SomeSubtype String),
    qw(__Directive __DirectiveLocation __EnumValue __Field __InputValue __Schema __Type __TypeKind)
  ] or diag explain [ sort keys %{$schema->name2type} ];
};

# NB for now, not overloading stringification, but providing to_string method
subtest 'stringifies simple types', sub {
  is $Int->to_string, 'Int';
  is $BlogArticle->to_string, 'Article';
  is $InterfaceType->to_string, 'Interface';
  is $UnionType->to_string, 'Union';
  is $EnumType->to_string, 'Enum';
  is $InputObjectType->to_string, 'InputObject';
  is($Int->non_null->to_string, 'Int!');
  is($Int->list->to_string, '[Int]');
  is($Int->list->non_null->to_string, '[Int]!');
  is($Int->non_null->list->to_string, '[Int!]');
  is($Int->list->list->to_string, '[[Int]]');
};

sub test_as_type {
  my ($type, $as, $should) = @_;
  $should = !!$should;
  map {
    my $got = !!$_->does("GraphQL::Role::$as");
    is $got, $should, "$_ $as ($should)";
  } $type, $type->list, $type->non_null;
}
subtest 'identifies input types', sub {
  test_as_type($Int, 'Input', 1);
  test_as_type($ObjectType, 'Input', '');
  test_as_type($InterfaceType, 'Input', '');
  test_as_type($UnionType, 'Input', '');
  test_as_type($EnumType, 'Input', 1);
  test_as_type($InputObjectType, 'Input', 1);
};

subtest 'identifies output types', sub {
  test_as_type($Int, 'Output', 1);
  test_as_type($ObjectType, 'Output', 1);
  test_as_type($InterfaceType, 'Output', 1);
  test_as_type($UnionType, 'Output', 1);
  test_as_type($EnumType, 'Output', 1);
  test_as_type($InputObjectType, 'Output', '');
};

subtest 'prohibits putting non-Object types in unions', sub {
  map { throws_ok { GraphQL::Type::Union->new(
    name => 'BadUnion',
    types => [ $_ ],
  )} qr/did not pass type constraint/ } (
    $Int,
    $Int->non_null,
    $Int->list,
    $InterfaceType,
    $UnionType,
    $EnumType,
    $InputObjectType,
  );
};

subtest 'allows a thunk for Union\'s types', sub {
  my $u = GraphQL::Type::Union->new(
    name => 'ThunkUnion',
    types => sub { [ $ObjectType ] },
  );
  is_deeply $u->types, [ $ObjectType ];
};

subtest 'does not mutate passed field definitions', sub {
  my $fields = {
    field1 => { type => $String, deprecation_reason => 'because' },
    field2 => { type => $String, args => { id => { type => $String } } },
  };
  my $o1 = GraphQL::Type::Object->new(name => 'O1', fields => $fields);
  my $o2 = GraphQL::Type::Object->new(name => 'O2', fields => $fields);
  is_deeply $o1->fields, $o2->fields;
  is_deeply $fields, {
    field1 => { type => $String, deprecation_reason => 'because' },
    field2 => { type => $String, args => { id => { type => $String } } },
  };
  my $fields2 = {
    field1 => { type => $String },
    field2 => { type => $String, default_value => 'hi' },
  };
  lives_ok {
    my $i1 = GraphQL::Type::InputObject->new(name => 'I1', fields => $fields2);
    my $i2 = GraphQL::Type::InputObject->new(name => 'I2', fields => $fields2);
    is_deeply $i1->fields, $i2->fields;
    is_deeply $fields2, {
      field1 => { type => $String },
      field2 => { type => $String, default_value => 'hi' },
    };
  };
};

subtest 'check default value type', sub {
  throws_ok { GraphQL::Type::InputObject->new(
    name => 'I1',
    fields => {
      ifield1 => { type => $String },
      ifield2 => { type => $Int, default_value => 'hi invalid' },
    },
  ) } qr/did not pass type constraint/;
};

subtest 'all other thunks', sub {
  lives_ok {
    my $SomeInputObject = GraphQL::Type::InputObject->new(
      name => 'SomeInputObject',
      fields => sub { { nested => { type => $Int } } },
    );
    is_deeply $SomeInputObject->fields, { nested => { type => $Int } };
  };
};

done_testing;
