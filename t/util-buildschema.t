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

done_testing;
