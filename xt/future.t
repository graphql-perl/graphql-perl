use strict;
use warnings;
use Test::More;
use GraphQL::Execution qw(execute);
use GraphQL::Schema;

BEGIN {
  eval "use Future";
  plan skip_all => "Future are required for this test" if $@;
  eval "use Safe::Isa";
  plan skip_all => "Safe::Isa are required for this test" if $@;
}

unless ( $ENV{RELEASE_TESTING} ) {
  plan( skip_all => "Author tests not required for installation" );
}

my $schema = GraphQL::Schema->from_doc(q|
  type Query {
    hello: String
  }
|);

my %root_value = (
  hello => sub {
    my ($args, $context, $info) = @_;
    return Future->done('world!!')
  }
);

my $query = q|
  {
    hello
  }
|;

my $promise_code =  +{
  then => sub {
    my ($future, $code) = @_;
    return $future->then(sub {
      my @normalized_results = $code->(@_);
      return Future->wrap(@normalized_results);
    });
  },
  all => sub {
    my @futures = map {
      $_->$_can('then') ? $_ : Future->done($_);
    } @_;
    Future->needs_all(map { $_->transform(done => sub { [@_] }) } @futures);
  },
  resolve => sub { Future->done(@_) },
  reject => sub { Future->fail(@_) },
};

ok my $results = execute(
  $schema,
  $query,
  \%root_value,
  undef,
  undef,
  undef,
  undef,
  $promise_code,  
);

ok $results->$_isa('Future');
ok my $data = $results->get;
ok $data->{data}{result}, 'world!!';

done_testing;
