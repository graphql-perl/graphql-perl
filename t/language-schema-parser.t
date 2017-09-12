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
                          'namedType' => {
                            'name' => 'QueryType'
                          }
                        }
                      ]
                    },
                    {
                      'operationTypeDefinition' => [
                        {
                          'operationType' => 'mutation'
                        },
                        {
                          'namedType' => {
                            'name' => 'MutationType'
                          }
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
                    {
                      'name' => 'Foo'
                    },
                    {
                      'implementsInterfaces' => [
                        [
                          {
                            'namedType' => {
                              'name' => 'Bar'
                            }
                          }
                        ]
                      ]
                    },
                    [
                      {
                        'fieldDefinition' => [
                          {
                            'name' => 'one'
                          },
                          {
                            'type' => [
                              {
                                'namedType' => {
                                  'name' => 'Type'
                                }
                              }
                            ]
                          }
                        ]
                      },
                      {
                        'fieldDefinition' => [
                          {
                            'name' => 'two'
                          },
                          {
                            'argumentsDefinition' => [
                              [
                                {
                                  'inputValueDefinition' => [
                                    {
                                      'name' => 'argument'
                                    },
                                    {
                                      'type' => [
                                        {
                                          'namedType' => {
                                            'name' => 'InputType'
                                          }
                                        }
                                      ]
                                    }
                                  ]
                                }
                              ]
                            ]
                          },
                          {
                            'type' => [
                              {
                                'namedType' => {
                                  'name' => 'Type'
                                }
                              }
                            ]
                          }
                        ]
                      },
                      {
                        'fieldDefinition' => [
                          {
                            'name' => 'three'
                          },
                          {
                            'argumentsDefinition' => [
                              [
                                {
                                  'inputValueDefinition' => [
                                    {
                                      'name' => 'argument'
                                    },
                                    {
                                      'type' => [
                                        {
                                          'namedType' => {
                                            'name' => 'InputType'
                                          }
                                        }
                                      ]
                                    }
                                  ]
                                },
                                {
                                  'inputValueDefinition' => [
                                    {
                                      'name' => 'other'
                                    },
                                    {
                                      'type' => [
                                        {
                                          'namedType' => {
                                            'name' => 'String'
                                          }
                                        }
                                      ]
                                    }
                                  ]
                                }
                              ]
                            ]
                          },
                          {
                            'type' => [
                              {
                                'namedType' => {
                                  'name' => 'Int'
                                }
                              }
                            ]
                          }
                        ]
                      },
                      {
                        'fieldDefinition' => [
                          {
                            'name' => 'four'
                          },
                          {
                            'argumentsDefinition' => [
                              [
                                {
                                  'inputValueDefinition' => [
                                    {
                                      'name' => 'argument'
                                    },
                                    {
                                      'type' => [
                                        {
                                          'namedType' => {
                                            'name' => 'String'
                                          }
                                        }
                                      ]
                                    },
                                    {
                                      'defaultValue' => [
                                        {
                                          'value_const' => {
                                            'string' => 'string'
                                          }
                                        }
                                      ]
                                    }
                                  ]
                                }
                              ]
                            ]
                          },
                          {
                            'type' => [
                              {
                                'namedType' => {
                                  'name' => 'String'
                                }
                              }
                            ]
                          }
                        ]
                      },
                      {
                        'fieldDefinition' => [
                          {
                            'name' => 'five'
                          },
                          {
                            'argumentsDefinition' => [
                              [
                                {
                                  'inputValueDefinition' => [
                                    {
                                      'name' => 'argument'
                                    },
                                    {
                                      'type' => [
                                        {
                                          'listType' => [
                                            {
                                              'type' => [
                                                {
                                                  'namedType' => {
                                                    'name' => 'String'
                                                  }
                                                }
                                              ]
                                            }
                                          ]
                                        }
                                      ]
                                    },
                                    {
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
                                      ]
                                    }
                                  ]
                                }
                              ]
                            ]
                          },
                          {
                            'type' => [
                              {
                                'namedType' => {
                                  'name' => 'String'
                                }
                              }
                            ]
                          }
                        ]
                      },
                      {
                        'fieldDefinition' => [
                          {
                            'name' => 'six'
                          },
                          {
                            'argumentsDefinition' => [
                              [
                                {
                                  'inputValueDefinition' => [
                                    {
                                      'name' => 'argument'
                                    },
                                    {
                                      'type' => [
                                        {
                                          'namedType' => {
                                            'name' => 'InputType'
                                          }
                                        }
                                      ]
                                    },
                                    {
                                      'defaultValue' => [
                                        {
                                          'value_const' => {
                                            'objectValue_const' => [
                                              [
                                                {
                                                  'objectField_const' => [
                                                    {
                                                      'name' => 'key'
                                                    },
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
                                      ]
                                    }
                                  ]
                                }
                              ]
                            ]
                          },
                          {
                            'type' => [
                              {
                                'namedType' => {
                                  'name' => 'Type'
                                }
                              }
                            ]
                          }
                        ]
                      },
                      {
                        'fieldDefinition' => [
                          {
                            'name' => 'seven'
                          },
                          {
                            'argumentsDefinition' => [
                              [
                                {
                                  'inputValueDefinition' => [
                                    {
                                      'name' => 'argument'
                                    },
                                    {
                                      'type' => [
                                        {
                                          'namedType' => {
                                            'name' => 'Int'
                                          }
                                        }
                                      ]
                                    },
                                    {
                                      'defaultValue' => []
                                    }
                                  ]
                                }
                              ]
                            ]
                          },
                          {
                            'type' => [
                              {
                                'namedType' => {
                                  'name' => 'Type'
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
                  'objectTypeDefinition' => [
                    {
                      'name' => 'AnnotatedObject'
                    },
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
                          {
                            'name' => 'annotatedField'
                          },
                          {
                            'argumentsDefinition' => [
                              [
                                {
                                  'inputValueDefinition' => [
                                    {
                                      'name' => 'arg'
                                    },
                                    {
                                      'type' => [
                                        {
                                          'namedType' => {
                                            'name' => 'Type'
                                          }
                                        }
                                      ]
                                    },
                                    {
                                      'defaultValue' => [
                                        {
                                          'value_const' => {
                                            'string' => 'default'
                                          }
                                        }
                                      ]
                                    },
                                    {
                                      'directives' => [
                                        {
                                          'directive' => {
                                            'name' => 'onArg'
                                          }
                                        }
                                      ]
                                    }
                                  ]
                                }
                              ]
                            ]
                          },
                          {
                            'type' => [
                              {
                                'namedType' => {
                                  'name' => 'Type'
                                }
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
                    {
                      'name' => 'Bar'
                    },
                    [
                      {
                        'fieldDefinition' => [
                          {
                            'name' => 'one'
                          },
                          {
                            'type' => [
                              {
                                'namedType' => {
                                  'name' => 'Type'
                                }
                              }
                            ]
                          }
                        ]
                      },
                      {
                        'fieldDefinition' => [
                          {
                            'name' => 'four'
                          },
                          {
                            'argumentsDefinition' => [
                              [
                                {
                                  'inputValueDefinition' => [
                                    {
                                      'name' => 'argument'
                                    },
                                    {
                                      'type' => [
                                        {
                                          'namedType' => {
                                            'name' => 'String'
                                          }
                                        }
                                      ]
                                    },
                                    {
                                      'defaultValue' => [
                                        {
                                          'value_const' => {
                                            'string' => 'string'
                                          }
                                        }
                                      ]
                                    }
                                  ]
                                }
                              ]
                            ]
                          },
                          {
                            'type' => [
                              {
                                'namedType' => {
                                  'name' => 'String'
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
                    {
                      'name' => 'AnnotatedInterface'
                    },
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
                          {
                            'name' => 'annotatedField'
                          },
                          {
                            'argumentsDefinition' => [
                              [
                                {
                                  'inputValueDefinition' => [
                                    {
                                      'name' => 'arg'
                                    },
                                    {
                                      'type' => [
                                        {
                                          'namedType' => {
                                            'name' => 'Type'
                                          }
                                        }
                                      ]
                                    },
                                    {
                                      'directives' => [
                                        {
                                          'directive' => {
                                            'name' => 'onArg'
                                          }
                                        }
                                      ]
                                    }
                                  ]
                                }
                              ]
                            ]
                          },
                          {
                            'type' => [
                              {
                                'namedType' => {
                                  'name' => 'Type'
                                }
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
                    {
                      'name' => 'Feed'
                    },
                    {
                      'unionMembers' => [
                        {
                          'namedType' => {
                            'name' => 'Story'
                          }
                        },
                        {
                          'namedType' => {
                            'name' => 'Article'
                          }
                        },
                        {
                          'namedType' => {
                            'name' => 'Advert'
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
                  'unionTypeDefinition' => [
                    {
                      'name' => 'AnnotatedUnion'
                    },
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
                          'namedType' => {
                            'name' => 'A'
                          }
                        },
                        {
                          'namedType' => {
                            'name' => 'B'
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
                  'scalarTypeDefinition' => [
                    {
                      'name' => 'CustomScalar'
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
                    {
                      'name' => 'AnnotatedScalar'
                    },
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
                    {
                      'name' => 'Site'
                    },
                    [
                      {
                        'enumValueDefinition' => [
                          {
                            'enumValue' => {
                              'name' => 'DESKTOP'
                            }
                          }
                        ]
                      },
                      {
                        'enumValueDefinition' => [
                          {
                            'enumValue' => {
                              'name' => 'MOBILE'
                            }
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
                    {
                      'name' => 'AnnotatedEnum'
                    },
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
                            'enumValue' => {
                              'name' => 'ANNOTATED_VALUE'
                            }
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
                            'enumValue' => {
                              'name' => 'OTHER_VALUE'
                            }
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
                    {
                      'name' => 'InputType'
                    },
                    [
                      {
                        'inputValueDefinition' => [
                          {
                            'name' => 'key'
                          },
                          {
                            'type' => [
                              {
                                'namedType' => {
                                  'name' => 'String'
                                }
                              }
                            ]
                          }
                        ]
                      },
                      {
                        'inputValueDefinition' => [
                          {
                            'name' => 'answer'
                          },
                          {
                            'type' => [
                              {
                                'namedType' => {
                                  'name' => 'Int'
                                }
                              }
                            ]
                          },
                          {
                            'defaultValue' => [
                              {
                                'value_const' => {
                                  'int' => '42'
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
                  'inputObjectTypeDefinition' => [
                    {
                      'name' => 'AnnotatedInput'
                    },
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
                        'inputValueDefinition' => [
                          {
                            'name' => 'annotatedField'
                          },
                          {
                            'type' => [
                              {
                                'namedType' => {
                                  'name' => 'Type'
                                }
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
                'typeExtensionDefinition' => [
                  {
                    'objectTypeDefinition' => [
                      {
                        'name' => 'Foo'
                      },
                      [
                        {
                          'fieldDefinition' => [
                            {
                              'name' => 'seven'
                            },
                            {
                              'argumentsDefinition' => [
                                [
                                  {
                                    'inputValueDefinition' => [
                                      {
                                        'name' => 'argument'
                                      },
                                      {
                                        'type' => [
                                          {
                                            'listType' => [
                                              {
                                                'type' => [
                                                  {
                                                    'namedType' => {
                                                      'name' => 'String'
                                                    }
                                                  }
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
                            },
                            {
                              'type' => [
                                {
                                  'namedType' => {
                                    'name' => 'Type'
                                  }
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
                      {
                        'name' => 'Foo'
                      },
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
                    {
                      'name' => 'NoFields'
                    },
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
                  {
                    'name' => 'skip'
                  },
                  {
                    'argumentsDefinition' => [
                      [
                        {
                          'inputValueDefinition' => [
                            {
                              'name' => 'if'
                            },
                            {
                              'type' => [
                                {
                                  'namedType' => {
                                    'name' => 'Boolean'
                                  }
                                }
                              ]
                            }
                          ]
                        }
                      ]
                    ]
                  },
                  {
                    'directiveLocations' => [
                      {
                        'name' => 'FIELD'
                      },
                      {
                        'name' => 'FRAGMENT_SPREAD'
                      },
                      {
                        'name' => 'INLINE_FRAGMENT'
                      }
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
                  {
                    'name' => 'include'
                  },
                  {
                    'argumentsDefinition' => [
                      [
                        {
                          'inputValueDefinition' => [
                            {
                              'name' => 'if'
                            },
                            {
                              'type' => [
                                {
                                  'namedType' => {
                                    'name' => 'Boolean'
                                  }
                                }
                              ]
                            }
                          ]
                        }
                      ]
                    ]
                  },
                  {
                    'directiveLocations' => [
                      {
                        'name' => 'FIELD'
                      },
                      {
                        'name' => 'FRAGMENT_SPREAD'
                      },
                      {
                        'name' => 'INLINE_FRAGMENT'
                      }
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
