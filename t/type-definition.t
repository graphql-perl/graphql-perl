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

done_testing;
