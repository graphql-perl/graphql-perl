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
{
  'graphql' => [
    [
      {
        'definition' => [
          {
            'typeSystemDefinition' => [
              {
                'schemaDefinition' => [
                  [
                    {
                      'operationTypeDefinition' => [
                        {
                          'operationType' => 'query'
                        },
                        'QueryType'
                      ]
                    },
                    {
                      'operationTypeDefinition' => [
                        {
                          'operationType' => 'mutation'
                        },
                        'MutationType'
                      ]
                    }
                  ]
                ]
              }
            ]
          }
        ]
      },
      {
        'definition' => [
          {
            'typeSystemDefinition' => [
              {
                'typeDefinition' => {
                  'objectTypeDefinition' => [
                    'Foo',
                    {
                      'implementsInterfaces' => [
                        [
                          'Bar'
                        ]
                      ]
                    },
                    [
                      {
                        'fieldDefinition' => [
                          'one',
                          {
                            'type' => [
                              'Type'
                            ]
                          }
                        ]
                      },
                      {
                        'fieldDefinition' => [
                          'two',
                          {
                            'argumentsDefinition' => [
                              [
                                {
                                  'inputValueDefinition' => {
                                    'name' => 'argument',
                                    'type' => [
                                      'InputType'
                                    ]
                                  }
                                }
                              ]
                            ]
                          },
                          {
                            'type' => [
                              'Type'
                            ]
                          }
                        ]
                      },
                      {
                        'fieldDefinition' => [
                          'three',
                          {
                            'argumentsDefinition' => [
                              [
                                {
                                  'inputValueDefinition' => {
                                    'name' => 'argument',
                                    'type' => [
                                      'InputType'
                                    ]
                                  }
                                },
                                {
                                  'inputValueDefinition' => {
                                    'name' => 'other',
                                    'type' => [
                                      'String'
                                    ]
                                  }
                                }
                              ]
                            ]
                          },
                          {
                            'type' => [
                              'Int'
                            ]
                          }
                        ]
                      },
                      {
                        'fieldDefinition' => [
                          'four',
                          {
                            'argumentsDefinition' => [
                              [
                                {
                                  'inputValueDefinition' => {
                                    'defaultValue' => {
                                      'default_value' => 'string',
                                      'type' => 'string'
                                    },
                                    'name' => 'argument',
                                    'type' => [
                                      'String'
                                    ]
                                  }
                                }
                              ]
                            ]
                          },
                          {
                            'type' => [
                              'String'
                            ]
                          }
                        ]
                      },
                      {
                        'fieldDefinition' => [
                          'five',
                          {
                            'argumentsDefinition' => [
                              [
                                {
                                  'inputValueDefinition' => {
                                    'defaultValue' => {
                                      'default_value' => [
                                        [
                                          {
                                            'value_const' => {
                                              'string' => 'string'
                                            }
                                          },
                                          {
                                            'value_const' => {
                                              'string' => 'string'
                                            }
                                          }
                                        ]
                                      ],
                                      'type' => 'listValue_const'
                                    },
                                    'name' => 'argument',
                                    'type' => [
                                      {
                                        'listType' => [
                                          {
                                            'type' => [
                                              'String'
                                            ]
                                          }
                                        ]
                                      }
                                    ]
                                  }
                                }
                              ]
                            ]
                          },
                          {
                            'type' => [
                              'String'
                            ]
                          }
                        ]
                      },
                      {
                        'fieldDefinition' => [
                          'six',
                          {
                            'argumentsDefinition' => [
                              [
                                {
                                  'inputValueDefinition' => {
                                    'defaultValue' => {
                                      'default_value' => [
                                        [
                                          {
                                            'objectField_const' => [
                                              'key',
                                              {
                                                'value_const' => {
                                                  'string' => 'value'
                                                }
                                              }
                                            ]
                                          }
                                        ]
                                      ],
                                      'type' => 'objectValue_const'
                                    },
                                    'name' => 'argument',
                                    'type' => [
                                      'InputType'
                                    ]
                                  }
                                }
                              ]
                            ]
                          },
                          {
                            'type' => [
                              'Type'
                            ]
                          }
                        ]
                      },
                      {
                        'fieldDefinition' => [
                          'seven',
                          {
                            'argumentsDefinition' => [
                              [
                                {
                                  'inputValueDefinition' => {
                                    'defaultValue' => {
                                      'default_value' => 'null',
                                      'type' => 'null'
                                    },
                                    'name' => 'argument',
                                    'type' => [
                                      'Int'
                                    ]
                                  }
                                }
                              ]
                            ]
                          },
                          {
                            'type' => [
                              'Type'
                            ]
                          }
                        ]
                      }
                    ]
                  ]
                }
              }
            ]
          }
        ]
      },
      {
        'definition' => [
          {
            'typeSystemDefinition' => [
              {
                'typeDefinition' => {
                  'objectTypeDefinition' => [
                    'AnnotatedObject',
                    {
                      'directives' => [
                        {
                          'directive' => {
                            'arguments' => {
                              'arg' => {
                                'type' => 'string',
                                'value' => 'value'
                              }
                            },
                            'name' => 'onObject'
                          }
                        }
                      ]
                    },
                    [
                      {
                        'fieldDefinition' => [
                          'annotatedField',
                          {
                            'argumentsDefinition' => [
                              [
                                {
                                  'inputValueDefinition' => {
                                    'defaultValue' => {
                                      'default_value' => 'default',
                                      'type' => 'string'
                                    },
                                    'directives' => [
                                      {
                                        'directive' => {
                                          'name' => 'onArg'
                                        }
                                      }
                                    ],
                                    'name' => 'arg',
                                    'type' => [
                                      'Type'
                                    ]
                                  }
                                }
                              ]
                            ]
                          },
                          {
                            'type' => [
                              'Type'
                            ]
                          },
                          {
                            'directives' => [
                              {
                                'directive' => {
                                  'name' => 'onField'
                                }
                              }
                            ]
                          }
                        ]
                      }
                    ]
                  ]
                }
              }
            ]
          }
        ]
      },
      {
        'definition' => [
          {
            'typeSystemDefinition' => [
              {
                'typeDefinition' => {
                  'interfaceTypeDefinition' => [
                    'Bar',
                    [
                      {
                        'fieldDefinition' => [
                          'one',
                          {
                            'type' => [
                              'Type'
                            ]
                          }
                        ]
                      },
                      {
                        'fieldDefinition' => [
                          'four',
                          {
                            'argumentsDefinition' => [
                              [
                                {
                                  'inputValueDefinition' => {
                                    'defaultValue' => {
                                      'default_value' => 'string',
                                      'type' => 'string'
                                    },
                                    'name' => 'argument',
                                    'type' => [
                                      'String'
                                    ]
                                  }
                                }
                              ]
                            ]
                          },
                          {
                            'type' => [
                              'String'
                            ]
                          }
                        ]
                      }
                    ]
                  ]
                }
              }
            ]
          }
        ]
      },
      {
        'definition' => [
          {
            'typeSystemDefinition' => [
              {
                'typeDefinition' => {
                  'interfaceTypeDefinition' => [
                    'AnnotatedInterface',
                    {
                      'directives' => [
                        {
                          'directive' => {
                            'name' => 'onInterface'
                          }
                        }
                      ]
                    },
                    [
                      {
                        'fieldDefinition' => [
                          'annotatedField',
                          {
                            'argumentsDefinition' => [
                              [
                                {
                                  'inputValueDefinition' => {
                                    'directives' => [
                                      {
                                        'directive' => {
                                          'name' => 'onArg'
                                        }
                                      }
                                    ],
                                    'name' => 'arg',
                                    'type' => [
                                      'Type'
                                    ]
                                  }
                                }
                              ]
                            ]
                          },
                          {
                            'type' => [
                              'Type'
                            ]
                          },
                          {
                            'directives' => [
                              {
                                'directive' => {
                                  'name' => 'onField'
                                }
                              }
                            ]
                          }
                        ]
                      }
                    ]
                  ]
                }
              }
            ]
          }
        ]
      },
      {
        'definition' => [
          {
            'typeSystemDefinition' => [
              {
                'typeDefinition' => {
                  'unionTypeDefinition' => [
                    'Feed',
                    {
                      'unionMembers' => [
                        'Story',
                        'Article',
                        'Advert'
                      ]
                    }
                  ]
                }
              }
            ]
          }
        ]
      },
      {
        'definition' => [
          {
            'typeSystemDefinition' => [
              {
                'typeDefinition' => {
                  'unionTypeDefinition' => [
                    'AnnotatedUnion',
                    {
                      'directives' => [
                        {
                          'directive' => {
                            'name' => 'onUnion'
                          }
                        }
                      ]
                    },
                    {
                      'unionMembers' => [
                        'A',
                        'B'
                      ]
                    }
                  ]
                }
              }
            ]
          }
        ]
      },
      {
        'definition' => [
          {
            'typeSystemDefinition' => [
              {
                'typeDefinition' => {
                  'scalarTypeDefinition' => {
                    'name' => 'CustomScalar'
                  }
                }
              }
            ]
          }
        ]
      },
      {
        'definition' => [
          {
            'typeSystemDefinition' => [
              {
                'typeDefinition' => {
                  'scalarTypeDefinition' => {
                    'directives' => [
                      {
                        'directive' => {
                          'name' => 'onScalar'
                        }
                      }
                    ],
                    'name' => 'AnnotatedScalar'
                  }
                }
              }
            ]
          }
        ]
      },
      {
        'definition' => [
          {
            'typeSystemDefinition' => [
              {
                'typeDefinition' => {
                  'enumTypeDefinition' => [
                    'Site',
                    [
                      {
                        'enumValueDefinition' => {
                          'value' => {
                            'enumValue' => 'DESKTOP'
                          }
                        }
                      },
                      {
                        'enumValueDefinition' => {
                          'value' => {
                            'enumValue' => 'MOBILE'
                          }
                        }
                      }
                    ]
                  ]
                }
              }
            ]
          }
        ]
      },
      {
        'definition' => [
          {
            'typeSystemDefinition' => [
              {
                'typeDefinition' => {
                  'enumTypeDefinition' => [
                    'AnnotatedEnum',
                    {
                      'directives' => [
                        {
                          'directive' => {
                            'name' => 'onEnum'
                          }
                        }
                      ]
                    },
                    [
                      {
                        'enumValueDefinition' => {
                          'directives' => [
                            {
                              'directive' => {
                                'name' => 'onEnumValue'
                              }
                            }
                          ],
                          'value' => {
                            'enumValue' => 'ANNOTATED_VALUE'
                          }
                        }
                      },
                      {
                        'enumValueDefinition' => {
                          'value' => {
                            'enumValue' => 'OTHER_VALUE'
                          }
                        }
                      }
                    ]
                  ]
                }
              }
            ]
          }
        ]
      },
      {
        'definition' => [
          {
            'typeSystemDefinition' => [
              {
                'typeDefinition' => {
                  'inputObjectTypeDefinition' => [
                    'InputType',
                    [
                      {
                        'inputValueDefinition' => {
                          'name' => 'key',
                          'type' => [
                            'String'
                          ]
                        }
                      },
                      {
                        'inputValueDefinition' => {
                          'defaultValue' => {
                            'default_value' => '42',
                            'type' => 'int'
                          },
                          'name' => 'answer',
                          'type' => [
                            'Int'
                          ]
                        }
                      }
                    ]
                  ]
                }
              }
            ]
          }
        ]
      },
      {
        'definition' => [
          {
            'typeSystemDefinition' => [
              {
                'typeDefinition' => {
                  'inputObjectTypeDefinition' => [
                    'AnnotatedInput',
                    {
                      'directives' => [
                        {
                          'directive' => {
                            'name' => 'onInputObjectType'
                          }
                        }
                      ]
                    },
                    [
                      {
                        'inputValueDefinition' => {
                          'directives' => [
                            {
                              'directive' => {
                                'name' => 'onField'
                              }
                            }
                          ],
                          'name' => 'annotatedField',
                          'type' => [
                            'Type'
                          ]
                        }
                      }
                    ]
                  ]
                }
              }
            ]
          }
        ]
      },
      {
        'definition' => [
          {
            'typeSystemDefinition' => [
              {
                'typeExtensionDefinition' => [
                  {
                    'objectTypeDefinition' => [
                      'Foo',
                      [
                        {
                          'fieldDefinition' => [
                            'seven',
                            {
                              'argumentsDefinition' => [
                                [
                                  {
                                    'inputValueDefinition' => {
                                      'name' => 'argument',
                                      'type' => [
                                        {
                                          'listType' => [
                                            {
                                              'type' => [
                                                'String'
                                              ]
                                            }
                                          ]
                                        }
                                      ]
                                    }
                                  }
                                ]
                              ]
                            },
                            {
                              'type' => [
                                'Type'
                              ]
                            }
                          ]
                        }
                      ]
                    ]
                  }
                ]
              }
            ]
          }
        ]
      },
      {
        'definition' => [
          {
            'typeSystemDefinition' => [
              {
                'typeExtensionDefinition' => [
                  {
                    'objectTypeDefinition' => [
                      'Foo',
                      {
                        'directives' => [
                          {
                            'directive' => {
                              'name' => 'onType'
                            }
                          }
                        ]
                      },
                      []
                    ]
                  }
                ]
              }
            ]
          }
        ]
      },
      {
        'definition' => [
          {
            'typeSystemDefinition' => [
              {
                'typeDefinition' => {
                  'objectTypeDefinition' => [
                    'NoFields',
                    []
                  ]
                }
              }
            ]
          }
        ]
      },
      {
        'definition' => [
          {
            'typeSystemDefinition' => [
              {
                'directiveDefinition' => [
                  'skip',
                  {
                    'argumentsDefinition' => [
                      [
                        {
                          'inputValueDefinition' => {
                            'name' => 'if',
                            'type' => [
                              'Boolean'
                            ]
                          }
                        }
                      ]
                    ]
                  },
                  {
                    'directiveLocations' => [
                      'FIELD',
                      'FRAGMENT_SPREAD',
                      'INLINE_FRAGMENT'
                    ]
                  }
                ]
              }
            ]
          }
        ]
      },
      {
        'definition' => [
          {
            'typeSystemDefinition' => [
              {
                'directiveDefinition' => [
                  'include',
                  {
                    'argumentsDefinition' => [
                      [
                        {
                          'inputValueDefinition' => {
                            'name' => 'if',
                            'type' => [
                              'Boolean'
                            ]
                          }
                        }
                      ]
                    ]
                  },
                  {
                    'directiveLocations' => [
                      'FIELD',
                      'FRAGMENT_SPREAD',
                      'INLINE_FRAGMENT'
                    ]
                  }
                ]
              }
            ]
          }
        ]
      }
    ]
  ]
}
