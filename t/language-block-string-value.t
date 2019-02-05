use lib 't/lib';
use GQLTest;
use GraphQL::Language::Parser qw(parse);

blockstring_test([
  '',
  '    Hello,',
  '      World!',
  '',
  '    Yours,',
  '      GraphQL.',
], ['Hello,', '  World!', '', 'Yours,', '  GraphQL.'], 'removes uniform indentation from a string');

blockstring_test([
  '',
  '',
  '    Hello,',
  '      World!',
  '',
  '    Yours,',
  '      GraphQL.',
  '',
  '',
], ['Hello,', '  World!', '', 'Yours,', '  GraphQL.'], 'removes empty leading and trailing lines');

blockstring_test([
  '  ',
  '        ',
  '    Hello,',
  '      World!',
  '',
  '    Yours,',
  '      GraphQL.',
  '        ',
  '  ',
], ['Hello,', '  World!', '', 'Yours,', '  GraphQL.'], 'removes blank leading and trailing lines');

blockstring_test([
  '    Hello,',
  '      World!',
  '',
  '    Yours,',
  '      GraphQL.',
], ['    Hello,', '  World!', '', 'Yours,', '  GraphQL.'], 'retains indentation from first line');

blockstring_test([
  '               ',
  '    Hello,     ',
  '      World!   ',
  '               ',
  '    Yours,     ',
  '      GraphQL. ',
  '               ',
], [
  'Hello,     ',
  '  World!   ',
  '           ',
  'Yours,     ',
  '  GraphQL. ',
], 'does not alter trailing spaces');

done_testing;

sub blockstring_test {
  my ($raw, $expect, $msg) = @_;
  my $got = parse(string_make(join("\n", @$raw)));
  is string_lookup($got), join("\n", @$expect), $msg or diag explain $got;
}

sub string_make {
  my ($text) = @_;
  return query_make(sprintf '"""%s"""', $text);
}

sub query_make {
  my ($text) = @_;
  return sprintf 'query q { foo(name: %s) { id } }', $text;
}

sub string_lookup {
  my ($got) = @_;
  return query_lookup($got, 'string');
}

sub query_lookup {
  my ($got, $type) = @_;
  return $got->[0]{selections}[0]{arguments}{name};
}
