#!perl -T
use 5.014;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use JSON::MaybeXS;
use Data::Dumper;

# differences from js version:
#  no try to treat true as string
#  no include bad field names as perl version violently rejects

BEGIN {
  use_ok( 'GraphQL::Schema' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Object' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Scalar', qw($String $Int $Boolean $ID) ) || print "Bail out!\n";
  use_ok( 'GraphQL::Execution', qw(execute) ) || print "Bail out!\n";
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
      resolve => sub {
        my ($obj, $args) = @_;
        $obj->{pic}->($args->{width}, $args->{height});
      },
    },
    recentArticle => { type => $BlogArticle },
  } },
);

$BlogArticle = GraphQL::Type::Object->new(
  name => 'Article',
  fields => {
    id => { type => $String->non_null },
    isPublished => { type => $Boolean },
    author => { type => $BlogAuthor },
    title => { type => $String },
    body => { type => $String },
    keywords => { type => $String->list },
  },
);

my $BlogQuery = GraphQL::Type::Object->new(
  name => 'Query',
  fields => {
    article => {
      type => $BlogArticle,
      args => { id => { type => $ID } },
      resolve => sub {
        my (undef, $args) = @_;
        article($args->{id});
      },
    },
    feed => {
      type => $BlogArticle->list,
      resolve => sub { [ map article($_), (1..10) ] },
    },
  },
);

my $schema = GraphQL::Schema->new(query => $BlogQuery);

my $johnSmith = {
  id => 123,
  name => 'John Smith',
  pic => sub { get_pic(123, shift, shift) },
  recentArticle => article(1),
};

sub article {
  my ($id) = @_;
  {
    id => $id, 
    isPublished => 1,
    author => $johnSmith,
    title => "My Article $id",
    body => 'This is a post',
    hidden => 'This data is not exposed in the schema',
    keywords => [ 'foo', 'bar', 1, undef ],
  };
}

sub get_pic {
  my ($uid, $width, $height) = @_;
  { url => "cdn://$uid", width => $width, height => $height };
}

my $doc = '{
  feed {
    id,
    title
  },
  article(id: "1") {
    ...articleFields,
    author {
      id,
      name,
      pic(width: 640, height: 480) {
        url,
        width,
        height
      },
      recentArticle {
        ...articleFields,
        keywords
      }
    }
  }
}
fragment articleFields on Article {
  id,
  isPublished,
  title,
  body,
}';

sub run_test {
  my ($args, $expected) = @_;
  my $got = execute(@$args);
  local ($Data::Dumper::Sortkeys, $Data::Dumper::Indent, $Data::Dumper::Terse);
  $Data::Dumper::Sortkeys = $Data::Dumper::Indent = $Data::Dumper::Terse = 1;
  is_deeply $got, $expected or diag Dumper $got;
}

subtest 'executes using a schema', sub {
  run_test(
    [ $schema, $doc ],
    {
      data => {
        feed => [
          { id => '1',
            title => 'My Article 1' },
          { id => '2',
            title => 'My Article 2' },
          { id => '3',
            title => 'My Article 3' },
          { id => '4',
            title => 'My Article 4' },
          { id => '5',
            title => 'My Article 5' },
          { id => '6',
            title => 'My Article 6' },
          { id => '7',
            title => 'My Article 7' },
          { id => '8',
            title => 'My Article 8' },
          { id => '9',
            title => 'My Article 9' },
          { id => '10',
            title => 'My Article 10' }
        ],
        article => {
          id => '1',
          isPublished => JSON->true,
          title => 'My Article 1',
          body => 'This is a post',
          author => {
            id => '123',
            name => 'John Smith',
            pic => {
              url => 'cdn://123',
              width => 640,
              height => 480,
            },
            recentArticle => {
              id => '1',
              isPublished => JSON->true,
              title => 'My Article 1',
              body => 'This is a post',
              keywords => [ 'foo', 'bar', '1', undef ],
            }
          }
        }
      }
    },
  );
  done_testing;
};

done_testing;
