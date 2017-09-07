#!perl -T
use 5.014;
use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
  use_ok( 'GraphQL::Type::Interface' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Object' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::List' ) || print "Bail out!\n";
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
    feed => { type => GraphQL::Type::List->new(of => $BlogArticle) },
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
  is_deeply $schema->name2type, {
    'Article' => $BlogArticle,
    'Author' => $BlogAuthor,
    'Boolean' => $Boolean,
    'Image' => $BlogImage,
    'Int' => $Int,
    'NestedInputObject' => $NestedInputObject,
    'Query' => $BlogQuery,
    'SomeInputObject' => $SomeInputObject,
    'SomeMutation' => $SomeMutation,
    'SomeSubscription' => $SomeSubscription,
    'String' => $String,
  };
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
  is_deeply $schema->name2type, {
    'Int' => $Int,
    'Query' => $query,
    'SomeInterface' => $SomeInterface,
    'SomeSubtype' => $SomeSubtype,
  };
};

done_testing;
