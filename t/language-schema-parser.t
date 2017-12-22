use lib 't/lib';
use GQLTest;

BEGIN {
  use_ok( 'GraphQL::Language::Parser', qw(parse) ) || print "Bail out!\n";
}

lives_ok { parse('type Hello { world: String }') } 'simple schema';
lives_ok { parse('extend type Hello { world: String }') } 'simple extend';
lives_ok { parse('type Hello { world: String! }') } 'non-null';
lives_ok { parse('type Hello implements World { }') } 'implements';
lives_ok { parse('type Hello implements Wo, rld { }') } 'implements multi';
lives_ok { parse('enum Hello { WORLD }') } 'single enum';
lives_ok { parse('enum Hello { WO, RLD }') } 'multi enum';
dies_ok { parse('enum Hello { true }') };
like $@->message, qr/Invalid enum value/, 'invalid enum';
dies_ok { parse('enum Hello { false }') };
like $@->message, qr/Invalid enum value/, 'invalid enum';
dies_ok { parse('enum Hello { null }') };
like $@->message, qr/Invalid enum value/, 'invalid enum';
lives_ok { parse('interface Hello { world: String }') } 'simple interface';
lives_ok { parse('type Hello { world(flag: Boolean): String }') } 'type with arg';
lives_ok { parse('type Hello { world(flag: Boolean = true): String }') } 'type with default arg';
lives_ok { parse('type Hello { world(things: [String]): String }') } 'type with list arg';
lives_ok { parse('type Hello { world(argOne: Boolean, argTwo: Int): String }') } 'type with two args';
lives_ok { parse('union Hello = World') } 'simple union';
lives_ok { parse('union Hello = Wo | Rld') } 'union of two';
lives_ok { parse('scalar Hello') } 'scalar';
lives_ok { parse('input Hello { world: String }') } 'simple input';
dies_ok { parse('input Hello { world(foo: Int): String }') };
like $@->message, qr/Parse document failed/, 'input with arg should fail';

open my $fh, '<', 't/schema-kitchen-sink.graphql';
my $got = parse(join('', <$fh>));
my $expected_text = join '', <DATA>;
$expected_text =~ s#bless\(\s*do\{\\\(my\s*\$o\s*=\s*(.)\)\},\s*'JSON::PP::Boolean'\s*\)#'JSON->' . ($1 ? 'true' : 'false')#ge;
my $expected = eval $expected_text;
#open $fh, '>', 'tf'; print $fh nice_dump $got; # uncomment this line to regen
is_deeply $got, $expected, 'lex big doc correct' or diag nice_dump $got;

done_testing;

__DATA__
[
  {
    'description' => 'Copyright (c) 2015, Facebook, Inc.
All rights reserved.

This source code is licensed under the BSD-style license found in the
LICENSE file in the root directory of this source tree. An additional grant
of patent rights can be found in the PATENTS file in the same directory.',
    'kind' => 'schema',
    'location' => {
      'column' => 0,
      'line' => 11
    },
    'mutation' => 'MutationType',
    'query' => 'QueryType'
  },
  {
    'fields' => {
      'five' => {
        'args' => {
          'argument' => {
            'default_value' => [
              'string',
              'string'
            ],
            'type' => [
              'list',
              {
                'type' => 'String'
              }
            ]
          }
        },
        'type' => 'String'
      },
      'four' => {
        'args' => {
          'argument' => {
            'default_value' => 'string',
            'type' => 'String'
          }
        },
        'type' => 'String'
      },
      'one' => {
        'type' => 'Type'
      },
      'seven' => {
        'args' => {
          'argument' => {
            'default_value' => undef,
            'type' => 'Int'
          }
        },
        'type' => 'Type'
      },
      'six' => {
        'args' => {
          'argument' => {
            'default_value' => {
              'key' => 'value'
            },
            'type' => 'InputType'
          }
        },
        'type' => 'Type'
      },
      'three' => {
        'args' => {
          'argument' => {
            'type' => 'InputType'
          },
          'other' => {
            'type' => 'String'
          }
        },
        'type' => 'Int'
      },
      'two' => {
        'args' => {
          'argument' => {
            'type' => [
              'non_null',
              {
                'type' => 'InputType'
              }
            ]
          }
        },
        'type' => 'Type'
      }
    },
    'interfaces' => [
      'Bar'
    ],
    'kind' => 'type',
    'location' => {
      'column' => 0,
      'line' => 21
    },
    'name' => 'Foo'
  },
  {
    'directives' => [
      {
        'arguments' => {
          'arg' => 'value'
        },
        'name' => 'onObject'
      }
    ],
    'fields' => {
      'annotatedField' => {
        'args' => {
          'arg' => {
            'default_value' => 'default',
            'directives' => [
              {
                'name' => 'onArg'
              }
            ],
            'type' => 'Type'
          }
        },
        'directives' => [
          {
            'name' => 'onField'
          }
        ],
        'type' => 'Type'
      }
    },
    'kind' => 'type',
    'location' => {
      'column' => 0,
      'line' => 25
    },
    'name' => 'AnnotatedObject'
  },
  {
    'fields' => {
      'four' => {
        'args' => {
          'argument' => {
            'default_value' => 'string',
            'type' => 'String'
          }
        },
        'type' => 'String'
      },
      'one' => {
        'type' => 'Type'
      }
    },
    'kind' => 'interface',
    'location' => {
      'column' => 0,
      'line' => 30
    },
    'name' => 'Bar'
  },
  {
    'directives' => [
      {
        'name' => 'onInterface'
      }
    ],
    'fields' => {
      'annotatedField' => {
        'args' => {
          'arg' => {
            'directives' => [
              {
                'name' => 'onArg'
              }
            ],
            'type' => 'Type'
          }
        },
        'directives' => [
          {
            'name' => 'onField'
          }
        ],
        'type' => 'Type'
      }
    },
    'kind' => 'interface',
    'location' => {
      'column' => 0,
      'line' => 34
    },
    'name' => 'AnnotatedInterface'
  },
  {
    'kind' => 'union',
    'location' => {
      'column' => 1,
      'line' => 38
    },
    'name' => 'Feed',
    'types' => [
      'Story',
      'Article',
      'Advert'
    ]
  },
  {
    'directives' => [
      {
        'name' => 'onUnion'
      }
    ],
    'kind' => 'union',
    'location' => {
      'column' => 1,
      'line' => 40
    },
    'name' => 'AnnotatedUnion',
    'types' => [
      'A',
      'B'
    ]
  },
  {
    'kind' => 'scalar',
    'location' => {
      'column' => 1,
      'line' => 42
    },
    'name' => 'CustomScalar'
  },
  {
    'directives' => [
      {
        'name' => 'onScalar'
      }
    ],
    'kind' => 'scalar',
    'location' => {
      'column' => 0,
      'line' => 42
    },
    'name' => 'AnnotatedScalar'
  },
  {
    'kind' => 'enum',
    'location' => {
      'column' => 0,
      'line' => 47
    },
    'name' => 'Site',
    'values' => {
      'DESKTOP' => {},
      'MOBILE' => {}
    }
  },
  {
    'directives' => [
      {
        'name' => 'onEnum'
      }
    ],
    'kind' => 'enum',
    'location' => {
      'column' => 0,
      'line' => 52
    },
    'name' => 'AnnotatedEnum',
    'values' => {
      'ANNOTATED_VALUE' => {
        'directives' => [
          {
            'name' => 'onEnumValue'
          }
        ]
      },
      'OTHER_VALUE' => {}
    }
  },
  {
    'fields' => {
      'answer' => {
        'default_value' => 42,
        'type' => 'Int'
      },
      'key' => {
        'type' => [
          'non_null',
          {
            'type' => 'String'
          }
        ]
      }
    },
    'kind' => 'input',
    'location' => {
      'column' => 0,
      'line' => 57
    },
    'name' => 'InputType'
  },
  {
    'directives' => [
      {
        'name' => 'onInputObjectType'
      }
    ],
    'fields' => {
      'annotatedField' => {
        'directives' => [
          {
            'name' => 'onField'
          }
        ],
        'type' => 'Type'
      }
    },
    'kind' => 'input',
    'location' => {
      'column' => 0,
      'line' => 61
    },
    'name' => 'AnnotatedInput'
  },
  {
    'fields' => {
      'seven' => {
        'args' => {
          'argument' => {
            'type' => [
              'list',
              {
                'type' => 'String'
              }
            ]
          }
        },
        'type' => 'Type'
      }
    },
    'kind' => 'type',
    'location' => {
      'column' => 0,
      'line' => 65
    },
    'name' => 'Foo'
  },
  {
    'directives' => [
      {
        'name' => 'onType'
      }
    ],
    'fields' => {},
    'kind' => 'type',
    'location' => {
      'column' => 0,
      'line' => 67
    },
    'name' => 'Foo'
  },
  {
    'fields' => {},
    'kind' => 'type',
    'location' => {
      'column' => 0,
      'line' => 69
    },
    'name' => 'NoFields'
  },
  {
    'args' => {
      'if' => {
        'type' => [
          'non_null',
          {
            'type' => 'Boolean'
          }
        ]
      }
    },
    'kind' => 'directive',
    'location' => {
      'column' => 0,
      'line' => 71
    },
    'locations' => [
      'FIELD',
      'FRAGMENT_SPREAD',
      'INLINE_FRAGMENT'
    ],
    'name' => 'skip'
  },
  {
    'args' => {
      'if' => {
        'type' => [
          'non_null',
          {
            'type' => 'Boolean'
          }
        ]
      }
    },
    'kind' => 'directive',
    'location' => {
      'column' => 0,
      'line' => 76
    },
    'locations' => [
      'FIELD',
      'FRAGMENT_SPREAD',
      'INLINE_FRAGMENT'
    ],
    'name' => 'include'
  }
]
