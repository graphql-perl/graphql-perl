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
                        {
                          'namedType' => 'QueryType'
                        }
                      ]
                    },
                    {
                      'operationTypeDefinition' => [
                        {
                          'operationType' => 'mutation'
                        },
                        {
                          'namedType' => 'MutationType'
                        }
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
                          {
                            'namedType' => 'Bar'
                          }
                        ]
                      ]
                    },
                    [
                      {
                        'fieldDefinition' => [
                          'one',
                          {
                            'type' => [
                              {
                                'namedType' => 'Type'
                              }
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
                                      {
                                        'namedType' => 'InputType'
                                      }
                                    ]
                                  }
                                }
                              ]
                            ]
                          },
                          {
                            'type' => [
                              {
                                'namedType' => 'Type'
                              }
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
                                      {
                                        'namedType' => 'InputType'
                                      }
                                    ]
                                  }
                                },
                                {
                                  'inputValueDefinition' => {
                                    'name' => 'other',
                                    'type' => [
                                      {
                                        'namedType' => 'String'
                                      }
                                    ]
                                  }
                                }
                              ]
                            ]
                          },
                          {
                            'type' => [
                              {
                                'namedType' => 'Int'
                              }
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
                                    'defaultValue' => [
                                      {
                                        'value_const' => {
                                          'string' => 'string'
                                        }
                                      }
                                    ],
                                    'name' => 'argument',
                                    'type' => [
                                      {
                                        'namedType' => 'String'
                                      }
                                    ]
                                  }
                                }
                              ]
                            ]
                          },
                          {
                            'type' => [
                              {
                                'namedType' => 'String'
                              }
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
                                    'defaultValue' => [
                                      {
                                        'value_const' => {
                                          'listValue_const' => [
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
                                          ]
                                        }
                                      }
                                    ],
                                    'name' => 'argument',
                                    'type' => [
                                      {
                                        'listType' => [
                                          {
                                            'type' => [
                                              {
                                                'namedType' => 'String'
                                              }
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
                              {
                                'namedType' => 'String'
                              }
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
                                    'defaultValue' => [
                                      {
                                        'value_const' => {
                                          'objectValue_const' => [
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
                                          ]
                                        }
                                      }
                                    ],
                                    'name' => 'argument',
                                    'type' => [
                                      {
                                        'namedType' => 'InputType'
                                      }
                                    ]
                                  }
                                }
                              ]
                            ]
                          },
                          {
                            'type' => [
                              {
                                'namedType' => 'Type'
                              }
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
                                    'defaultValue' => [
                                      {
                                        'value_const' => {
                                          'null' => 'null'
                                        }
                                      }
                                    ],
                                    'name' => 'argument',
                                    'type' => [
                                      {
                                        'namedType' => 'Int'
                                      }
                                    ]
                                  }
                                }
                              ]
                            ]
                          },
                          {
                            'type' => [
                              {
                                'namedType' => 'Type'
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
                                    'defaultValue' => [
                                      {
                                        'value_const' => {
                                          'string' => 'default'
                                        }
                                      }
                                    ],
                                    'directives' => [
                                      {
                                        'directive' => {
                                          'name' => 'onArg'
                                        }
                                      }
                                    ],
                                    'name' => 'arg',
                                    'type' => [
                                      {
                                        'namedType' => 'Type'
                                      }
                                    ]
                                  }
                                }
                              ]
                            ]
                          },
                          {
                            'type' => [
                              {
                                'namedType' => 'Type'
                              }
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
                              {
                                'namedType' => 'Type'
                              }
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
                                    'defaultValue' => [
                                      {
                                        'value_const' => {
                                          'string' => 'string'
                                        }
                                      }
                                    ],
                                    'name' => 'argument',
                                    'type' => [
                                      {
                                        'namedType' => 'String'
                                      }
                                    ]
                                  }
                                }
                              ]
                            ]
                          },
                          {
                            'type' => [
                              {
                                'namedType' => 'String'
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
                                      {
                                        'namedType' => 'Type'
                                      }
                                    ]
                                  }
                                }
                              ]
                            ]
                          },
                          {
                            'type' => [
                              {
                                'namedType' => 'Type'
                              }
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
                        {
                          'namedType' => 'Story'
                        },
                        {
                          'namedType' => 'Article'
                        },
                        {
                          'namedType' => 'Advert'
                        }
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
                        {
                          'namedType' => 'A'
                        },
                        {
                          'namedType' => 'B'
                        }
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
                  'scalarTypeDefinition' => [
                    'CustomScalar'
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
                  'scalarTypeDefinition' => [
                    'AnnotatedScalar',
                    {
                      'directives' => [
                        {
                          'directive' => {
                            'name' => 'onScalar'
                          }
                        }
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
                  'enumTypeDefinition' => [
                    'Site',
                    [
                      {
                        'enumValueDefinition' => [
                          {
                            'enumValue' => 'DESKTOP'
                          }
                        ]
                      },
                      {
                        'enumValueDefinition' => [
                          {
                            'enumValue' => 'MOBILE'
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
                        'enumValueDefinition' => [
                          {
                            'enumValue' => 'ANNOTATED_VALUE'
                          },
                          {
                            'directives' => [
                              {
                                'directive' => {
                                  'name' => 'onEnumValue'
                                }
                              }
                            ]
                          }
                        ]
                      },
                      {
                        'enumValueDefinition' => [
                          {
                            'enumValue' => 'OTHER_VALUE'
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
                  'inputObjectTypeDefinition' => [
                    'InputType',
                    [
                      {
                        'inputValueDefinition' => {
                          'name' => 'key',
                          'type' => [
                            {
                              'namedType' => 'String'
                            }
                          ]
                        }
                      },
                      {
                        'inputValueDefinition' => {
                          'defaultValue' => [
                            {
                              'value_const' => {
                                'int' => '42'
                              }
                            }
                          ],
                          'name' => 'answer',
                          'type' => [
                            {
                              'namedType' => 'Int'
                            }
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
                            {
                              'namedType' => 'Type'
                            }
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
                                                {
                                                  'namedType' => 'String'
                                                }
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
                                {
                                  'namedType' => 'Type'
                                }
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
                              {
                                'namedType' => 'Boolean'
                              }
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
                              {
                                'namedType' => 'Boolean'
                              }
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
