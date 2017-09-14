use strict;
use warnings;
use Test::More;
use Test::Exception;
use Pegex::Parser;
use GraphQL::Grammar;
use GraphQL::Parser;
use Pegex::Tree::Wrap;
use Pegex::Input;
use Data::Dumper;

my $parser = Pegex::Parser->new(
  grammar => GraphQL::Grammar->new,
  receiver => GraphQL::Parser->new,
);
open my $fh, '<', 't/kitchen-sink.graphql';

my $got = do_lex(join('', <$fh>));
my $expected = eval join '', <DATA>;
local $Data::Dumper::Indent = $Data::Dumper::Sortkeys = $Data::Dumper::Terse = 1;
#open $fh, '>', 'tf'; print $fh Dumper $got; # uncomment to regenerate

is_deeply $got, $expected, 'lex big doc correct' or diag Dumper $got;

throws_ok { do_lex("\x{0007}") } qr/Parse document failed for some reason/, 'invalid char';

lives_ok { do_lex("\x{FEFF} query foo { id }") } 'accepts BOM';

throws_ok { do_lex("\n\n    ?  \n\n\n") } qr/line:\s*3.*column:\s*5/s, 'error respects whitespace';

$got = do_lex(string_make(' x '));
is string_lookup($got), ' x ', 'string preserve whitespace' or diag Dumper $got;

$got = do_lex(string_make('quote \\"'));
is string_lookup($got), 'quote \\"', 'string quote kept' or diag Dumper $got; # not de-quoted by lexer

throws_ok { do_lex(string_make('quote \\')) } qr/line:\s*1.*column:\s*21/s, 'error on unterminated string';

throws_ok { do_lex(q(query q { foo(name: 'hello') { id } })) } qr/line:\s*1.*column:\s*21/s, 'error on single quote';

throws_ok { do_lex("\x{0007}") } qr/line:\s*1.*column:\s*1/s, 'error on invalid char';

throws_ok { do_lex(string_make("\x{0000}")) } qr/line:\s*1.*column:\s*21/s, 'error on NUL char';

throws_ok { do_lex(string_make("hi\nthere")) } qr/line:\s*1.*column:\s*21/s, 'error on multi-line string';
throws_ok { do_lex(string_make("hi\rthere")) } qr/line:\s*1.*column:\s*21/s, 'error on MacOS multi-line string';

throws_ok { do_lex(string_make('\z')) } qr/line:\s*1.*column:\s*21/s, 'error on invalid escape';
throws_ok { do_lex(string_make('bad \\x esc')) } qr/line:\s*1.*column:\s*21/s, 'error on invalid escape';
throws_ok { do_lex(string_make('bad \\u1 esc')) } qr/line:\s*1.*column:\s*21/s, 'error on invalid escape';
throws_ok { do_lex(string_make('bad \\u0XX1 esc')) } qr/line:\s*1.*column:\s*21/s, 'error on invalid escape';
throws_ok { do_lex(string_make('bad \\uXXXX esc')) } qr/line:\s*1.*column:\s*21/s, 'error on invalid escape';
throws_ok { do_lex(string_make('bad \\uFXXX esc')) } qr/line:\s*1.*column:\s*21/s, 'error on invalid escape';
throws_ok { do_lex(string_make('bad \\uXXXF esc')) } qr/line:\s*1.*column:\s*21/s, 'error on invalid escape';

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

throws_ok { do_lex(number_make('00')) } qr/line:\s*1.*column:\s*22/s, 'error on invalid int';
throws_ok { do_lex(number_make('+1')) } qr/line:\s*1.*column:\s*21/s, 'error on invalid int';
throws_ok { do_lex(number_make('1.')) } qr/line:\s*1.*column:\s*22/s, 'error on invalid int';
throws_ok { do_lex(number_make('.123')) } qr/line:\s*1.*column:\s*21/s, 'error on invalid float';
throws_ok { do_lex(number_make('1.A')) } qr/line:\s*1.*column:\s*22/s, 'error on invalid int';
throws_ok { do_lex(number_make('-A')) } qr/line:\s*1.*column:\s*21/s, 'error on invalid int';
throws_ok { do_lex(number_make('1.0e')) } qr/line:\s*1.*column:\s*25/s, 'error on invalid int';
throws_ok { do_lex(number_make('1.0eA')) } qr/line:\s*1.*column:\s*26/s, 'error on invalid int';

my $multibyte = "Has a \x{0A0A} multi-byte character.";
$got = do_lex(string_make($multibyte));
is string_lookup($got), $multibyte, 'multibyte kept' or diag Dumper $got;

done_testing;

sub number_test {
  my ($text, $type, $label) = @_;
  my $got = do_lex(number_make($text));
  is query_lookup($got, $type), $text, $label or diag Dumper $got;
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
  return $got->{graphql}[0][0]{definition}[0]{operationDefinition}[2]{selectionSet}[0][0]{selection}{field}[1]{arguments}{name}{value};
}

sub do_lex {
  my ($text) = @_;
  my $input = Pegex::Input->new(string => $text);
  return $parser->parse($input);
}

__DATA__
{
  'graphql' => [
    [
      {
        'definition' => [
          {
            'operationDefinition' => [
              {
                'operationType' => 'query'
              },
              'queryName',
              {
                'variableDefinitions' => [
                  [
                    {
                      'variableDefinition' => [
                        {
                          'variable' => [
                            'foo'
                          ]
                        },
                        {
                          'type' => 'ComplexType'
                        }
                      ]
                    },
                    {
                      'variableDefinition' => [
                        {
                          'variable' => [
                            'site'
                          ]
                        },
                        {
                          'type' => 'Site'
                        },
                        {
                          'defaultValue' => {
                            'default_value' => 'MOBILE',
                            'type' => 'enumValue'
                          }
                        }
                      ]
                    }
                  ]
                ]
              },
              {
                'selectionSet' => [
                  [
                    {
                      'selection' => {
                        'field' => [
                          {
                            'alias' => [
                              'whoever123is'
                            ]
                          },
                          'node',
                          {
                            'arguments' => {
                              'id' => {
                                'type' => 'listValue',
                                'value' => [
                                  {
                                    'type' => 'int',
                                    'value' => '123'
                                  },
                                  {
                                    'type' => 'int',
                                    'value' => '456'
                                  }
                                ]
                              }
                            }
                          },
                          {
                            'selectionSet' => [
                              [
                                {
                                  'selection' => {
                                    'field' => [
                                      'id'
                                    ]
                                  }
                                },
                                {
                                  'selection' => {
                                    'inlineFragment' => [
                                      {
                                        'typeCondition' => [
                                          'User'
                                        ]
                                      },
                                      {
                                        'directives' => [
                                          {
                                            'directive' => {
                                              'name' => 'defer'
                                            }
                                          }
                                        ]
                                      },
                                      {
                                        'selectionSet' => [
                                          [
                                            {
                                              'selection' => {
                                                'field' => [
                                                  'field2',
                                                  {
                                                    'selectionSet' => [
                                                      [
                                                        {
                                                          'selection' => {
                                                            'field' => [
                                                              'id'
                                                            ]
                                                          }
                                                        },
                                                        {
                                                          'selection' => {
                                                            'field' => [
                                                              {
                                                                'alias' => [
                                                                  'alias'
                                                                ]
                                                              },
                                                              'field1',
                                                              {
                                                                'arguments' => {
                                                                  'after' => {
                                                                    'type' => 'variable',
                                                                    'value' => [
                                                                      'foo'
                                                                    ]
                                                                  },
                                                                  'first' => {
                                                                    'type' => 'int',
                                                                    'value' => '10'
                                                                  }
                                                                }
                                                              },
                                                              {
                                                                'directives' => [
                                                                  {
                                                                    'directive' => {
                                                                      'arguments' => {
                                                                        'if' => {
                                                                          'type' => 'variable',
                                                                          'value' => [
                                                                            'foo'
                                                                          ]
                                                                        }
                                                                      },
                                                                      'name' => 'include'
                                                                    }
                                                                  }
                                                                ]
                                                              },
                                                              {
                                                                'selectionSet' => [
                                                                  [
                                                                    {
                                                                      'selection' => {
                                                                        'field' => [
                                                                          'id'
                                                                        ]
                                                                      }
                                                                    },
                                                                    {
                                                                      'selection' => {
                                                                        'fragmentSpread' => [
                                                                          {
                                                                            'fragmentName' => 'frag'
                                                                          }
                                                                        ]
                                                                      }
                                                                    }
                                                                  ]
                                                                ]
                                                              }
                                                            ]
                                                          }
                                                        }
                                                      ]
                                                    ]
                                                  }
                                                ]
                                              }
                                            }
                                          ]
                                        ]
                                      }
                                    ]
                                  }
                                },
                                {
                                  'selection' => {
                                    'inlineFragment' => [
                                      {
                                        'directives' => [
                                          {
                                            'directive' => {
                                              'arguments' => {
                                                'unless' => {
                                                  'type' => 'variable',
                                                  'value' => [
                                                    'foo'
                                                  ]
                                                }
                                              },
                                              'name' => 'skip'
                                            }
                                          }
                                        ]
                                      },
                                      {
                                        'selectionSet' => [
                                          [
                                            {
                                              'selection' => {
                                                'field' => [
                                                  'id'
                                                ]
                                              }
                                            }
                                          ]
                                        ]
                                      }
                                    ]
                                  }
                                },
                                {
                                  'selection' => {
                                    'inlineFragment' => [
                                      {
                                        'selectionSet' => [
                                          [
                                            {
                                              'selection' => {
                                                'field' => [
                                                  'id'
                                                ]
                                              }
                                            }
                                          ]
                                        ]
                                      }
                                    ]
                                  }
                                }
                              ]
                            ]
                          }
                        ]
                      }
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
            'operationDefinition' => [
              {
                'operationType' => 'mutation'
              },
              'likeStory',
              {
                'selectionSet' => [
                  [
                    {
                      'selection' => {
                        'field' => [
                          'like',
                          {
                            'arguments' => {
                              'story' => {
                                'type' => 'int',
                                'value' => '123'
                              }
                            }
                          },
                          {
                            'directives' => [
                              {
                                'directive' => {
                                  'name' => 'defer'
                                }
                              }
                            ]
                          },
                          {
                            'selectionSet' => [
                              [
                                {
                                  'selection' => {
                                    'field' => [
                                      'story',
                                      {
                                        'selectionSet' => [
                                          [
                                            {
                                              'selection' => {
                                                'field' => [
                                                  'id'
                                                ]
                                              }
                                            }
                                          ]
                                        ]
                                      }
                                    ]
                                  }
                                }
                              ]
                            ]
                          }
                        ]
                      }
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
            'operationDefinition' => [
              {
                'operationType' => 'subscription'
              },
              'StoryLikeSubscription',
              {
                'variableDefinitions' => [
                  [
                    {
                      'variableDefinition' => [
                        {
                          'variable' => [
                            'input'
                          ]
                        },
                        {
                          'type' => 'StoryLikeSubscribeInput'
                        }
                      ]
                    }
                  ]
                ]
              },
              {
                'selectionSet' => [
                  [
                    {
                      'selection' => {
                        'field' => [
                          'storyLikeSubscribe',
                          {
                            'arguments' => {
                              'input' => {
                                'type' => 'variable',
                                'value' => [
                                  'input'
                                ]
                              }
                            }
                          },
                          {
                            'selectionSet' => [
                              [
                                {
                                  'selection' => {
                                    'field' => [
                                      'story',
                                      {
                                        'selectionSet' => [
                                          [
                                            {
                                              'selection' => {
                                                'field' => [
                                                  'likers',
                                                  {
                                                    'selectionSet' => [
                                                      [
                                                        {
                                                          'selection' => {
                                                            'field' => [
                                                              'count'
                                                            ]
                                                          }
                                                        }
                                                      ]
                                                    ]
                                                  }
                                                ]
                                              }
                                            },
                                            {
                                              'selection' => {
                                                'field' => [
                                                  'likeSentence',
                                                  {
                                                    'selectionSet' => [
                                                      [
                                                        {
                                                          'selection' => {
                                                            'field' => [
                                                              'text'
                                                            ]
                                                          }
                                                        }
                                                      ]
                                                    ]
                                                  }
                                                ]
                                              }
                                            }
                                          ]
                                        ]
                                      }
                                    ]
                                  }
                                }
                              ]
                            ]
                          }
                        ]
                      }
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
            'fragmentDefinition' => [
              {
                'fragmentName' => 'frag'
              },
              {
                'typeCondition' => [
                  'Friend'
                ]
              },
              {
                'selectionSet' => [
                  [
                    {
                      'selection' => {
                        'field' => [
                          'foo',
                          {
                            'arguments' => {
                              'bar' => {
                                'type' => 'variable',
                                'value' => [
                                  'b'
                                ]
                              },
                              'obj' => {
                                'type' => 'objectValue',
                                'value' => {
                                  'key' => {
                                    'type' => 'string',
                                    'value' => 'value'
                                  }
                                }
                              },
                              'size' => {
                                'type' => 'variable',
                                'value' => [
                                  'size'
                                ]
                              }
                            }
                          }
                        ]
                      }
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
            'operationDefinition' => {
              'selectionSet' => [
                [
                  {
                    'selection' => {
                      'field' => [
                        'unnamed',
                        {
                          'arguments' => {
                            'falsey' => {
                              'type' => 'boolean',
                              'value' => 'false'
                            },
                            'nullish' => {
                              'type' => 'null',
                              'value' => 'null'
                            },
                            'truthy' => {
                              'type' => 'boolean',
                              'value' => 'true'
                            }
                          }
                        }
                      ]
                    }
                  },
                  {
                    'selection' => {
                      'field' => [
                        'query'
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
  ]
}
