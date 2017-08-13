#!perl
use 5.014;
use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
  use_ok( 'GraphQL::Parser' ) || print "Bail out!\n";
}

throws_ok { do_parse('{') } qr/Expected name/, 'trivial fail';

throws_ok { do_parse(<<'EOF'
{ ...MissingOn }
fragment MissingOn Type
EOF
) } qr/Expected "on"/, 'missing "on"';

throws_ok { do_parse('{ field: {} }') } qr/Expected name/, 'expected';
throws_ok { do_parse('notanoperation Foo { field }') } qr/Parse document failed/, 'bad op';
throws_ok { do_parse('...') } qr/Parse document failed/, 'spread wrong place';

lives_ok { do_parse('{ field(complex: { a: { b: [ $var ] } }) }') } 'parses variable inline values';
throws_ok { do_parse('query Foo($x: Complex = { a: { b: [ $var ] } }) { field }') } qr/Expected name or constant/, 'no var in default values';
throws_ok { do_parse('fragment on on on { on }') } qr/Unexpected Name "on"/, 'no accept fragments named "on"';
throws_ok { do_parse('{ ...on }') } qr/Unexpected Name "on"/, 'no accept fragment spread named "on"';

my @nonKeywords = (
  'on',
  'fragment',
  'query',
  'mutation',
  'subscription',
  'true',
  'false',
);
my %k2sub = (on => 'a');
for my $keyword (@nonKeywords) {
  my $fragmentName = $k2sub{$keyword} || $keyword;
  lives_ok { do_parse(<<EOF) } 'non keywords allowed';
query $keyword {
  ... $fragmentName
  ... on $keyword { field }
}
fragment $fragmentName on Type {
  $keyword($keyword: \$$keyword) \@$keyword($keyword: $keyword)
}
EOF
}

for my $anon (qw(mutation subscription)) {
  lives_ok { do_parse(<<EOF) } 'non keywords allowed';
${anon} {
  ${anon}Field
}
EOF
}

lives_ok { do_parse('{ field(complex: { a: { b: [ 123 "abc" ] } }) }') } 'list values';

sub do_parse {
  return GraphQL::Parser->parse($_[0]);
}

done_testing;
