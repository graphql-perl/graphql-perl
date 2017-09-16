#!perl
use 5.014;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Data::Dumper;

BEGIN {
  use_ok( 'GraphQL::Parser' ) || print "Bail out!\n";
}

lives_ok { do_parse('type Hello { world: String }') } 'simple schema';
lives_ok { do_parse('extend type Hello { world: String }') } 'simple extend';
lives_ok { do_parse('type Hello { world: String! }') } 'non-null';
lives_ok { do_parse('type Hello implements World { }') } 'implements';
lives_ok { do_parse('type Hello implements Wo, rld { }') } 'implements multi';
lives_ok { do_parse('enum Hello { WORLD }') } 'single enum';
lives_ok { do_parse('enum Hello { WO, RLD }') } 'multi enum';
throws_ok { do_parse('enum Hello { true }') } qr/Invalid enum value/, 'invalid enum';
throws_ok { do_parse('enum Hello { false }') } qr/Invalid enum value/, 'invalid enum';
throws_ok { do_parse('enum Hello { null }') } qr/Invalid enum value/, 'invalid enum';
lives_ok { do_parse('interface Hello { world: String }') } 'simple interface';
lives_ok { do_parse('type Hello { world(flag: Boolean): String }') } 'type with arg';
lives_ok { do_parse('type Hello { world(flag: Boolean = true): String }') } 'type with default arg';
lives_ok { do_parse('type Hello { world(things: [String]): String }') } 'type with list arg';
lives_ok { do_parse('type Hello { world(argOne: Boolean, argTwo: Int): String }') } 'type with two args';
lives_ok { do_parse('union Hello = World') } 'simple union';
lives_ok { do_parse('union Hello = Wo | Rld') } 'union of two';
lives_ok { do_parse('scalar Hello') } 'scalar';
lives_ok { do_parse('input Hello { world: String }') } 'simple input';
throws_ok { do_parse('input Hello { world(foo: Int): String }') } qr/Parse document failed/, 'input with arg should fail';

open my $fh, '<', 't/schema-kitchen-sink.graphql';
my $got = do_parse(join('', <$fh>));
my $expected = eval join '', <DATA>;
local $Data::Dumper::Indent = $Data::Dumper::Sortkeys = $Data::Dumper::Terse = 1;
#open $fh, '>', 'tf'; print $fh Dumper $got; # uncomment this line to regen
is_deeply $got, $expected, 'lex big doc correct' or diag Dumper $got;

sub do_parse {
  return GraphQL::Parser->parse($_[0]);
}

done_testing;

__DATA__
[
  {
    'schema' => {
      'mutation' => 'MutationType',
      'query' => 'QueryType'
    }
  },
  {
    'typeDefinition' => {
      'objectTypeDefinition' => {
        'fields' => {
          'five' => {
            'args' => {
              'argument' => {
                'default_value' => [
                  'string',
                  'string'
                ],
                'type' => {
                  'listType' => [
                    {
                      'type' => 'String'
                    }
                  ]
                }
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
                'type' => {
                  'nonNullType' => [
                    'InputType'
                  ]
                }
              }
            },
            'type' => 'Type'
          }
        },
        'interfaces' => [
          'Bar'
        ],
        'name' => 'Foo'
      }
    }
  },
  {
    'typeDefinition' => {
      'objectTypeDefinition' => {
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
        'name' => 'AnnotatedObject'
      }
    }
  },
  {
    'typeDefinition' => {
      'interfaceTypeDefinition' => {
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
        'name' => 'Bar'
      }
    }
  },
  {
    'typeDefinition' => {
      'interfaceTypeDefinition' => {
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
        'name' => 'AnnotatedInterface'
      }
    }
  },
  {
    'typeDefinition' => {
      'unionTypeDefinition' => {
        'name' => 'Feed',
        'types' => [
          'Story',
          'Article',
          'Advert'
        ]
      }
    }
  },
  {
    'typeDefinition' => {
      'unionTypeDefinition' => {
        'directives' => [
          {
            'name' => 'onUnion'
          }
        ],
        'name' => 'AnnotatedUnion',
        'types' => [
          'A',
          'B'
        ]
      }
    }
  },
  {
    'typeDefinition' => {
      'scalarTypeDefinition' => {
        'name' => 'CustomScalar'
      }
    }
  },
  {
    'typeDefinition' => {
      'scalarTypeDefinition' => {
        'directives' => [
          {
            'name' => 'onScalar'
          }
        ],
        'name' => 'AnnotatedScalar'
      }
    }
  },
  {
    'typeDefinition' => {
      'enumTypeDefinition' => {
        'name' => 'Site',
        'values' => {
          'DESKTOP' => {},
          'MOBILE' => {}
        }
      }
    }
  },
  {
    'typeDefinition' => {
      'enumTypeDefinition' => {
        'directives' => [
          {
            'name' => 'onEnum'
          }
        ],
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
    }
  },
  {
    'typeDefinition' => {
      'inputObjectTypeDefinition' => {
        'fields' => {
          'answer' => {
            'default_value' => '42',
            'type' => 'Int'
          },
          'key' => {
            'type' => {
              'nonNullType' => [
                'String'
              ]
            }
          }
        },
        'name' => 'InputType'
      }
    }
  },
  {
    'typeDefinition' => {
      'inputObjectTypeDefinition' => {
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
        'name' => 'AnnotatedInput'
      }
    }
  },
  {
    'typeExtensionDefinition' => [
      {
        'objectTypeDefinition' => {
          'fields' => {
            'seven' => {
              'args' => {
                'argument' => {
                  'type' => {
                    'listType' => [
                      {
                        'type' => 'String'
                      }
                    ]
                  }
                }
              },
              'type' => 'Type'
            }
          },
          'name' => 'Foo'
        }
      }
    ]
  },
  {
    'typeExtensionDefinition' => [
      {
        'objectTypeDefinition' => {
          'directives' => [
            {
              'name' => 'onType'
            }
          ],
          'fields' => {},
          'name' => 'Foo'
        }
      }
    ]
  },
  {
    'typeDefinition' => {
      'objectTypeDefinition' => {
        'fields' => {},
        'name' => 'NoFields'
      }
    }
  },
  {
    'directive' => {
      'args' => {
        'if' => {
          'type' => {
            'nonNullType' => [
              'Boolean'
            ]
          }
        }
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
    'directive' => {
      'args' => {
        'if' => {
          'type' => {
            'nonNullType' => [
              'Boolean'
            ]
          }
        }
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
