use lib 't/lib';
use GQLTest;
use GraphQL::Language::Parser qw(parse);

open my $fh, '<', 't/kitchen-sink.graphql';
my $got = parse(join('', <$fh>));
lives_ok {
  my $expected_text = join '', <DATA>;
  $expected_text =~ s#bless\(\s*do\{\\\(my\s*\$o\s*=\s*(.)\)\},\s*'JSON::PP::Boolean'\s*\)#'JSON->' . ($1 ? 'true' : 'false')#ge;
  my $expected = eval $expected_text;
  #open $fh, '>', 'tf'; print $fh nice_dump $got; # uncomment to regenerate
  is_deeply $got, $expected, 'lex big doc correct' or diag nice_dump $got;
} or diag explain $@;

dies_ok { parse("\x{0007}") };
like $@->message, qr/Parse document failed for some reason/, 'invalid char';

lives_ok { parse("\x{FEFF} query foo { id }") } 'accepts BOM';

dies_ok { parse("\n\n    ?  \n\n\n") };
is_deeply [ map $@->locations->[0]->{$_}, qw(line column) ], [3,5], 'error respects whitespace';

$got = parse(string_make(' x '));
is string_lookup($got), ' x ', 'string preserve whitespace' or diag nice_dump $got;

$got = parse(string_make('quote \\"'));
is string_lookup($got), 'quote "', 'string quote kept' or diag nice_dump $got;

dies_ok { parse(string_make('quote \\')) };
is_deeply [map $@->locations->[0]->{$_}, qw(line column)], [1,21], 'error on unterminated string';

dies_ok { parse(q(query q { foo(name: 'hello') { id } })) };
is_deeply [map $@->locations->[0]->{$_}, qw(line column)], [1,21], 'error on single quote';

dies_ok { parse("\x{0007}") };
is_deeply [map $@->locations->[0]->{$_}, qw(line column)], [1,1], 'error on invalid char';

dies_ok { parse(string_make("\x{0000}")) };
is_deeply [map $@->locations->[0]->{$_}, qw(line column)], [1,21], 'error on NUL char';

dies_ok { parse(string_make("hi\nthere")) };
is_deeply [map $@->locations->[0]->{$_}, qw(line column)], [1,21], 'error on multi-line string';
dies_ok { parse(string_make("hi\rthere")) };
is_deeply [map $@->locations->[0]->{$_}, qw(line column)], [1,21], 'error on MacOS multi-line string';

dies_ok { parse(string_make('\z')) };
is_deeply [map $@->locations->[0]->{$_}, qw(line column)], [1,21], 'error on invalid escape';
dies_ok { parse(string_make('bad \\x esc')) };
is_deeply [map $@->locations->[0]->{$_}, qw(line column)], [1,21], 'error on invalid escape';
dies_ok { parse(string_make('bad \\u1 esc')) };
is_deeply [map $@->locations->[0]->{$_}, qw(line column)], [1,21], 'error on invalid escape';
dies_ok { parse(string_make('bad \\u0XX1 esc')) };
is_deeply [map $@->locations->[0]->{$_}, qw(line column)], [1,21], 'error on invalid escape';
dies_ok { parse(string_make('bad \\uXXXX esc')) };
is_deeply [map $@->locations->[0]->{$_}, qw(line column)], [1,21], 'error on invalid escape';
dies_ok { parse(string_make('bad \\uFXXX esc')) };
is_deeply [map $@->locations->[0]->{$_}, qw(line column)], [1,21], 'error on invalid escape';
dies_ok { parse(string_make('bad \\uXXXF esc')) };
is_deeply [map $@->locations->[0]->{$_}, qw(line column)], [1,21], 'error on invalid escape';

number_test('4', 'int', 'simple int');
number_test('4.123', 'float', 'simple float');
number_test('9', 'int', 'simple int');
number_test('0', 'int', 'simple int');
number_test('-4.123', 'float', 'negative float');
number_test('0.123', 'float', 'simple float 0');
number_test('123e4', 'float', 'float exp lower');
number_test('123E4', 'float', 'float exp upper');
number_test('123e-4', 'float', 'float negexp lower');
number_test('123e+4', 'float', 'float posexp lower');
number_test('-1.123e4', 'float', 'neg float exp lower');
number_test('-1.123E4', 'float', 'neg float exp upper');
number_test('-1.123e-4', 'float', 'neg float negexp lower');
number_test('-1.123e+4', 'float', 'neg float posexp lower');
number_test('-1.123e4567', 'float', 'neg float longexp lower');

dies_ok { parse(number_make('00')) };
is_deeply [map $@->locations->[0]->{$_}, qw(line column)], [1,22], 'error on invalid int';
dies_ok { parse(number_make('+1')) };
is_deeply [map $@->locations->[0]->{$_}, qw(line column)], [1,21], 'error on invalid int';
dies_ok { parse(number_make('1.')) };
is_deeply [map $@->locations->[0]->{$_}, qw(line column)], [1,22], 'error on invalid int';
dies_ok { parse(number_make('.123')) };
is_deeply [map $@->locations->[0]->{$_}, qw(line column)], [1,21], 'error on invalid float';
dies_ok { parse(number_make('1.A')) };
is_deeply [map $@->locations->[0]->{$_}, qw(line column)], [1,22], 'error on invalid int';
dies_ok { parse(number_make('-A')) };
is_deeply [map $@->locations->[0]->{$_}, qw(line column)], [1,21], 'error on invalid int';
dies_ok { parse(number_make('1.0e')) };
is_deeply [map $@->locations->[0]->{$_}, qw(line column)], [1,25], 'error on invalid int';
dies_ok { parse(number_make('1.0eA')) };
is_deeply [map $@->locations->[0]->{$_}, qw(line column)], [1,26], 'error on invalid int';

my $multibyte = "Has a \x{0A0A} multi-byte character.";
$got = parse(string_make($multibyte));
is string_lookup($got), $multibyte, 'multibyte kept' or diag nice_dump $got;

done_testing;

sub number_test {
  my ($text, $type, $label) = @_;
  my $got = parse(number_make($text));
  cmp_ok query_lookup($got, $type), '==', $text, $label or diag nice_dump $got;
}

sub number_make {
  my ($text) = @_;
  return query_make($text);
}

sub string_make {
  my ($text) = @_;
  return query_make(sprintf '"%s"', $text);
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

__DATA__
[
  {
    'directives' => [
      {
        'name' => 'onQuery'
      }
    ],
    'kind' => 'operation',
    'location' => {
      'column' => 1,
      'line' => 27
    },
    'name' => 'queryName',
    'operationType' => 'query',
    'selections' => [
      {
        'alias' => 'whoever123is',
        'arguments' => {
          'id' => [
            123,
            456
          ]
        },
        'kind' => 'field',
        'location' => {
          'column' => 1,
          'line' => 25
        },
        'name' => 'node',
        'selections' => [
          {
            'kind' => 'field',
            'location' => {
              'column' => 5,
              'line' => 9
            },
            'name' => 'id'
          },
          {
            'directives' => [
              {
                'name' => 'onInlineFragment'
              }
            ],
            'kind' => 'inline_fragment',
            'location' => {
              'column' => 5,
              'line' => 18
            },
            'on' => 'User',
            'selections' => [
              {
                'kind' => 'field',
                'location' => {
                  'column' => 5,
                  'line' => 17
                },
                'name' => 'field2',
                'selections' => [
                  {
                    'kind' => 'field',
                    'location' => {
                      'column' => 9,
                      'line' => 12
                    },
                    'name' => 'id'
                  },
                  {
                    'alias' => 'alias',
                    'arguments' => {
                      'after' => \'foo',
                      'first' => 10
                    },
                    'directives' => [
                      {
                        'arguments' => {
                          'if' => \'foo'
                        },
                        'name' => 'include'
                      }
                    ],
                    'kind' => 'field',
                    'location' => {
                      'column' => 7,
                      'line' => 16
                    },
                    'name' => 'field1',
                    'selections' => [
                      {
                        'kind' => 'field',
                        'location' => {
                          'column' => 11,
                          'line' => 14
                        },
                        'name' => 'id'
                      },
                      {
                        'directives' => [
                          {
                            'name' => 'onFragmentSpread'
                          }
                        ],
                        'kind' => 'fragment_spread',
                        'location' => {
                          'column' => 0,
                          'line' => 14
                        },
                        'name' => 'frag'
                      }
                    ]
                  }
                ]
              }
            ]
          },
          {
            'directives' => [
              {
                'arguments' => {
                  'unless' => \'foo'
                },
                'name' => 'skip'
              }
            ],
            'kind' => 'inline_fragment',
            'location' => {
              'column' => 5,
              'line' => 21
            },
            'selections' => [
              {
                'kind' => 'field',
                'location' => {
                  'column' => 5,
                  'line' => 20
                },
                'name' => 'id'
              }
            ]
          },
          {
            'kind' => 'inline_fragment',
            'location' => {
              'column' => 3,
              'line' => 24
            },
            'selections' => [
              {
                'kind' => 'field',
                'location' => {
                  'column' => 5,
                  'line' => 23
                },
                'name' => 'id'
              }
            ]
          }
        ]
      }
    ],
    'variables' => {
      'foo' => {
        'type' => 'ComplexType'
      },
      'site' => {
        'default_value' => \\'MOBILE',
        'type' => 'Site'
      }
    }
  },
  {
    'directives' => [
      {
        'name' => 'onMutation'
      }
    ],
    'kind' => 'operation',
    'location' => {
      'column' => 1,
      'line' => 35
    },
    'name' => 'likeStory',
    'operationType' => 'mutation',
    'selections' => [
      {
        'arguments' => {
          'story' => 123
        },
        'directives' => [
          {
            'name' => 'onField'
          }
        ],
        'kind' => 'field',
        'location' => {
          'column' => 1,
          'line' => 33
        },
        'name' => 'like',
        'selections' => [
          {
            'kind' => 'field',
            'location' => {
              'column' => 3,
              'line' => 32
            },
            'name' => 'story',
            'selections' => [
              {
                'directives' => [
                  {
                    'name' => 'onField'
                  }
                ],
                'kind' => 'field',
                'location' => {
                  'column' => 0,
                  'line' => 30
                },
                'name' => 'id'
              }
            ]
          }
        ]
      }
    ]
  },
  {
    'directives' => [
      {
        'name' => 'onSubscription'
      }
    ],
    'kind' => 'operation',
    'location' => {
      'column' => 1,
      'line' => 50
    },
    'name' => 'StoryLikeSubscription',
    'operationType' => 'subscription',
    'selections' => [
      {
        'arguments' => {
          'input' => \'input'
        },
        'kind' => 'field',
        'location' => {
          'column' => 1,
          'line' => 48
        },
        'name' => 'storyLikeSubscribe',
        'selections' => [
          {
            'kind' => 'field',
            'location' => {
              'column' => 3,
              'line' => 47
            },
            'name' => 'story',
            'selections' => [
              {
                'kind' => 'field',
                'location' => {
                  'column' => 7,
                  'line' => 43
                },
                'name' => 'likers',
                'selections' => [
                  {
                    'kind' => 'field',
                    'location' => {
                      'column' => 7,
                      'line' => 42
                    },
                    'name' => 'count'
                  }
                ]
              },
              {
                'kind' => 'field',
                'location' => {
                  'column' => 5,
                  'line' => 46
                },
                'name' => 'likeSentence',
                'selections' => [
                  {
                    'kind' => 'field',
                    'location' => {
                      'column' => 7,
                      'line' => 45
                    },
                    'name' => 'text'
                  }
                ]
              }
            ]
          }
        ]
      }
    ],
    'variables' => {
      'input' => {
        'type' => 'StoryLikeSubscribeInput'
      }
    }
  },
  {
    'directives' => [
      {
        'name' => 'onFragmentDefinition'
      }
    ],
    'kind' => 'fragment',
    'location' => {
      'column' => 1,
      'line' => 58
    },
    'name' => 'frag',
    'on' => 'Friend',
    'selections' => [
      {
        'arguments' => {
          'bar' => \'b',
          'obj' => {
            'block' => 'block string uses """',
            'key' => 'value'
          },
          'size' => \'size'
        },
        'kind' => 'field',
        'location' => {
          'column' => 1,
          'line' => 56
        },
        'name' => 'foo'
      }
    ]
  },
  {
    'kind' => 'operation',
    'location' => {
      'column' => 1,
      'line' => 63
    },
    'selections' => [
      {
        'arguments' => {
          'falsey' => bless( do{\(my $o = 0)}, 'JSON::PP::Boolean' ),
          'nullish' => undef,
          'truthy' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' )
        },
        'kind' => 'field',
        'location' => {
          'column' => 3,
          'line' => 60
        },
        'name' => 'unnamed'
      },
      {
        'kind' => 'field',
        'location' => {
          'column' => 1,
          'line' => 61
        },
        'name' => 'query'
      }
    ]
  },
  {
    'kind' => 'operation',
    'location' => {
      'column' => 1,
      'line' => 64
    },
    'operationType' => 'query',
    'selections' => [
      {
        'kind' => 'field',
        'location' => {
          'column' => 20,
          'line' => 63
        },
        'name' => '__typename'
      }
    ]
  }
]
