#!perl
use 5.014;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Data::Dumper;
use JSON::MaybeXS;

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
local $Data::Dumper::Indent = $Data::Dumper::Sortkeys = $Data::Dumper::Terse = 1;
#open $fh, '>', 'tf'; print $fh Dumper $got; # uncomment this line to regen
is_deeply $got, $expected, 'lex big doc correct' or diag Dumper $got;

done_testing;

__DATA__
[
  {
    'kind' => 'schema',
    'node' => {
      'location' => {
        'column' => 1,
        'line' => 13
      },
      'mutation' => 'MutationType',
      'query' => 'QueryType'
    }
  },
  {
    'kind' => 'type',
    'node' => {
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
      'location' => {
        'column' => 1,
        'line' => 23
      },
      'name' => 'Foo'
    }
  },
  {
    'kind' => 'type',
    'node' => {
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
      'location' => {
        'column' => 1,
        'line' => 27
      },
      'name' => 'AnnotatedObject'
    }
  },
  {
    'kind' => 'interface',
    'node' => {
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
      'location' => {
        'column' => 1,
        'line' => 32
      },
      'name' => 'Bar'
    }
  },
  {
    'kind' => 'interface',
    'node' => {
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
      'location' => {
        'column' => 1,
        'line' => 36
      },
      'name' => 'AnnotatedInterface'
    }
  },
  {
    'kind' => 'union',
    'node' => {
      'location' => {
        'column' => 0,
        'line' => 36
      },
      'name' => 'Feed',
      'types' => [
        'Story',
        'Article',
        'Advert'
      ]
    }
  },
  {
    'kind' => 'union',
    'node' => {
      'directives' => [
        {
          'name' => 'onUnion'
        }
      ],
      'location' => {
        'column' => 0,
        'line' => 38
      },
      'name' => 'AnnotatedUnion',
      'types' => [
        'A',
        'B'
      ]
    }
  },
  {
    'kind' => 'scalar',
    'node' => {
      'location' => {
        'column' => 1,
        'line' => 42
      },
      'name' => 'CustomScalar'
    }
  },
  {
    'kind' => 'scalar',
    'node' => {
      'directives' => [
        {
          'name' => 'onScalar'
        }
      ],
      'location' => {
        'column' => 0,
        'line' => 42
      },
      'name' => 'AnnotatedScalar'
    }
  },
  {
    'kind' => 'enum',
    'node' => {
      'location' => {
        'column' => 1,
        'line' => 49
      },
      'name' => 'Site',
      'values' => {
        'DESKTOP' => {},
        'MOBILE' => {}
      }
    }
  },
  {
    'kind' => 'enum',
    'node' => {
      'directives' => [
        {
          'name' => 'onEnum'
        }
      ],
      'location' => {
        'column' => 1,
        'line' => 54
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
    }
  },
  {
    'kind' => 'input',
    'node' => {
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
      'location' => {
        'column' => 1,
        'line' => 59
      },
      'name' => 'InputType'
    }
  },
  {
    'kind' => 'input',
    'node' => {
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
      'location' => {
        'column' => 1,
        'line' => 63
      },
      'name' => 'AnnotatedInput'
    }
  },
  {
    'kind' => 'extend',
    'node' => {
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
      'location' => {
        'column' => 1,
        'line' => 67
      },
      'name' => 'Foo'
    }
  },
  {
    'kind' => 'extend',
    'node' => {
      'directives' => [
        {
          'name' => 'onType'
        }
      ],
      'fields' => {},
      'location' => {
        'column' => 1,
        'line' => 69
      },
      'name' => 'Foo'
    }
  },
  {
    'kind' => 'type',
    'node' => {
      'fields' => {},
      'location' => {
        'column' => 1,
        'line' => 71
      },
      'name' => 'NoFields'
    }
  },
  {
    'kind' => 'directive',
    'node' => {
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
    }
  },
  {
    'kind' => 'directive',
    'node' => {
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
  }
]
