package GraphQL::Language::Grammar;

use 5.014;
use strict;
use warnings;
use base 'Pegex::Grammar';
use constant file => './graphql.pgx';

our $VERSION = '0.02';

=head1 NAME

GraphQL::Language::Grammar - GraphQL grammar

=head1 SYNOPSIS

  use Pegex::Parser;
  use GraphQL::Language::Grammar;
  use Pegex::Tree::Wrap;
  use Pegex::Input;

  my $parser = Pegex::Parser->new(
    grammar => GraphQL::Language::Grammar->new,
    receiver => Pegex::Tree::Wrap->new,
  );
  my $text = 'query q { foo(name: "hi") { id } }';
  my $input = Pegex::Input->new(string => $text);
  my $got = $parser->parse($input);

=head1 DESCRIPTION

This is a subclass of L<Pegex::Grammar>, with the GraphQL grammar.

=head1 METHODS

=head2 make_tree

Override method from L<Pegex::Grammar>.

=cut

sub make_tree {   # Generated/Inlined by Pegex::Grammar (0.64)
  {
    '+grammar' => 'graphql',
    '+include' => 'pegex-atoms',
    '+toprule' => 'graphql',
    '+version' => '0.01',
    'LSQUARE' => {
      '.rgx' => qr/\G\[/
    },
    'RSQUARE' => {
      '.rgx' => qr/\G\]/
    },
    '_' => {
      '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
    },
    'alias' => {
      '.all' => [
        {
          '.ref' => 'name'
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*:(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        }
      ]
    },
    'argument' => {
      '.all' => [
        {
          '.ref' => 'name'
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*:(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.ref' => 'value'
        }
      ]
    },
    'arguments' => {
      '.all' => [
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\((?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.all' => [
            {
              '.ref' => 'argument'
            },
            {
              '+min' => 0,
              '-flat' => 1,
              '.all' => [
                {
                  '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
                },
                {
                  '.ref' => 'argument'
                }
              ]
            },
            {
              '+max' => 1,
              '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
            }
          ]
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\)(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        }
      ]
    },
    'argumentsDefinition' => {
      '.all' => [
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\((?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.all' => [
            {
              '.ref' => 'inputValueDefinition'
            },
            {
              '+min' => 0,
              '-flat' => 1,
              '.all' => [
                {
                  '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
                },
                {
                  '.ref' => 'inputValueDefinition'
                }
              ]
            }
          ]
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\)(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        }
      ]
    },
    'boolean' => {
      '.rgx' => qr/\G(true|false)/
    },
    'defaultValue' => {
      '.all' => [
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*=(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.ref' => 'value_const'
        }
      ]
    },
    'definition' => {
      '.all' => [
        {
          '.ref' => '_'
        },
        {
          '.any' => [
            {
              '.ref' => 'operationDefinition'
            },
            {
              '.ref' => 'fragment'
            },
            {
              '.ref' => 'typeSystemDefinition'
            }
          ]
        }
      ]
    },
    'directive' => {
      '.all' => [
        {
          '.rgx' => qr/\Gdirective(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\@(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.ref' => 'name'
        },
        {
          '.ref' => '_'
        },
        {
          '+max' => 1,
          '.ref' => 'argumentsDefinition'
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*on(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.ref' => 'directiveLocations'
        }
      ]
    },
    'directiveLocations' => {
      '.all' => [
        {
          '.ref' => 'name'
        },
        {
          '+min' => 0,
          '-flat' => 1,
          '.all' => [
            {
              '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\|(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
            },
            {
              '.ref' => 'name'
            }
          ]
        }
      ]
    },
    'directiveactual' => {
      '.all' => [
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\@/u
        },
        {
          '.ref' => 'name'
        },
        {
          '+max' => 1,
          '.ref' => 'arguments'
        }
      ]
    },
    'directives' => {
      '+min' => 1,
      '.ref' => 'directiveactual'
    },
    'enumTypeDefinition' => {
      '.all' => [
        {
          '.rgx' => qr/\Genum(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.ref' => 'name'
        },
        {
          '.ref' => '_'
        },
        {
          '+max' => 1,
          '.ref' => 'directives'
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\{(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.all' => [
            {
              '.ref' => 'enumValueDefinition'
            },
            {
              '+min' => 0,
              '-flat' => 1,
              '.all' => [
                {
                  '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
                },
                {
                  '.ref' => 'enumValueDefinition'
                }
              ]
            }
          ]
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\}(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        }
      ]
    },
    'enumValue' => {
      '.any' => [
        {
          '.all' => [
            {
              '.rgx' => qr/\G(true|false|null)/
            },
            {
              '.err' => 'Invalid enum value'
            }
          ]
        },
        {
          '.ref' => 'name'
        }
      ]
    },
    'enumValueDefinition' => {
      '.all' => [
        {
          '.ref' => 'enumValue'
        },
        {
          '.ref' => '_'
        },
        {
          '+max' => 1,
          '.ref' => 'directives'
        }
      ]
    },
    'field' => {
      '.all' => [
        {
          '+max' => 1,
          '.ref' => 'alias'
        },
        {
          '.ref' => 'name'
        },
        {
          '.ref' => '_'
        },
        {
          '+max' => 1,
          '.ref' => 'arguments'
        },
        {
          '.ref' => '_'
        },
        {
          '+max' => 1,
          '.ref' => 'directives'
        },
        {
          '+max' => 1,
          '.ref' => 'selectionSet'
        }
      ]
    },
    'fieldDefinition' => {
      '.all' => [
        {
          '.ref' => 'name'
        },
        {
          '.ref' => '_'
        },
        {
          '+max' => 1,
          '.ref' => 'argumentsDefinition'
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*:(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.ref' => 'typedef'
        },
        {
          '.ref' => '_'
        },
        {
          '+max' => 1,
          '.ref' => 'directives'
        }
      ]
    },
    'float' => {
      '.rgx' => qr/\G(\-?(?:0|[1-9][0-9]*)(?:(?:\.[0-9]+)(?:[eE][\-\+]?[0-9]+)|(?:\.[0-9]+)|(?:[eE][\-\+]?[0-9]+)))/
    },
    'fragment' => {
      '.all' => [
        {
          '.rgx' => qr/\Gfragment(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.ref' => 'fragmentName'
        },
        {
          '.ref' => '_'
        },
        {
          '.any' => [
            {
              '.ref' => 'typeCondition'
            },
            {
              '.err' => 'Expected "on"'
            }
          ]
        },
        {
          '.ref' => '_'
        },
        {
          '+max' => 1,
          '.ref' => 'directives'
        },
        {
          '.ref' => '_'
        },
        {
          '.ref' => 'selectionSet'
        }
      ]
    },
    'fragmentName' => {
      '.any' => [
        {
          '.all' => [
            {
              '.rgx' => qr/\Gon/
            },
            {
              '.err' => 'Unexpected Name "on"'
            }
          ]
        },
        {
          '.ref' => 'name'
        }
      ]
    },
    'fragment_spread' => {
      '.all' => [
        {
          '-skip' => 1,
          '.ref' => 'spread'
        },
        {
          '.ref' => 'fragmentName'
        },
        {
          '.ref' => '_'
        },
        {
          '+max' => 1,
          '.ref' => 'directives'
        }
      ]
    },
    'graphql' => {
      '.all' => [
        {
          '.ref' => '_'
        },
        {
          '+min' => 1,
          '.ref' => 'definition'
        },
        {
          '.rgx' => qr/\G\z/
        }
      ]
    },
    'implementsInterfaces' => {
      '.all' => [
        {
          '.rgx' => qr/\Gimplements(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.all' => [
            {
              '.ref' => 'namedType'
            },
            {
              '+min' => 0,
              '-flat' => 1,
              '.all' => [
                {
                  '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
                },
                {
                  '.ref' => 'namedType'
                }
              ]
            }
          ]
        }
      ]
    },
    'inline_fragment' => {
      '.all' => [
        {
          '-skip' => 1,
          '.ref' => 'spread'
        },
        {
          '+max' => 1,
          '.ref' => 'typeCondition'
        },
        {
          '.ref' => '_'
        },
        {
          '+max' => 1,
          '.ref' => 'directives'
        },
        {
          '.ref' => '_'
        },
        {
          '.ref' => 'selectionSet'
        }
      ]
    },
    'input' => {
      '.all' => [
        {
          '.rgx' => qr/\Ginput(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.ref' => 'name'
        },
        {
          '.ref' => '_'
        },
        {
          '+max' => 1,
          '.ref' => 'directives'
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\{(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '+min' => 1,
          '.ref' => 'inputValueDefinition'
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\}(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        }
      ]
    },
    'inputValueDefinition' => {
      '.all' => [
        {
          '.ref' => 'name'
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*:(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.ref' => 'typedef'
        },
        {
          '.ref' => '_'
        },
        {
          '+max' => 1,
          '.ref' => 'defaultValue'
        },
        {
          '.ref' => '_'
        },
        {
          '+max' => 1,
          '.ref' => 'directives'
        }
      ]
    },
    'int' => {
      '.rgx' => qr/\G(\-?(?:0|[1-9][0-9]*))/
    },
    'interface' => {
      '.all' => [
        {
          '.rgx' => qr/\Ginterface(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.ref' => 'name'
        },
        {
          '.ref' => '_'
        },
        {
          '+max' => 1,
          '.ref' => 'directives'
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\{(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '+min' => 1,
          '.ref' => 'fieldDefinition'
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\}(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        }
      ]
    },
    'listType' => {
      '.all' => [
        {
          '.ref' => 'LSQUARE'
        },
        {
          '.ref' => 'typedef'
        },
        {
          '.ref' => 'RSQUARE'
        }
      ]
    },
    'listValue' => {
      '.all' => [
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\[(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '+max' => 1,
          '.all' => [
            {
              '.ref' => 'value'
            },
            {
              '+min' => 0,
              '-flat' => 1,
              '.all' => [
                {
                  '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
                },
                {
                  '.ref' => 'value'
                }
              ]
            }
          ]
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\](?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        }
      ]
    },
    'listValue_const' => {
      '.all' => [
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\[(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '+max' => 1,
          '.all' => [
            {
              '.ref' => 'value_const'
            },
            {
              '+min' => 0,
              '-flat' => 1,
              '.all' => [
                {
                  '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
                },
                {
                  '.ref' => 'value_const'
                }
              ]
            }
          ]
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\](?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        }
      ]
    },
    'name' => {
      '.rgx' => qr/\G([_a-zA-Z][0-9A-Za-z_]*)/
    },
    'namedType' => {
      '.ref' => 'name'
    },
    'nonNullType' => {
      '.any' => [
        {
          '.all' => [
            {
              '.ref' => 'namedType'
            },
            {
              '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*!/u
            }
          ]
        },
        {
          '.all' => [
            {
              '.ref' => 'listType'
            },
            {
              '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*!/u
            }
          ]
        }
      ]
    },
    'null' => {
      '.rgx' => qr/\G(null)/
    },
    'objectField' => {
      '.all' => [
        {
          '.ref' => 'name'
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*:(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.ref' => 'value'
        }
      ]
    },
    'objectField_const' => {
      '.all' => [
        {
          '.ref' => 'name'
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*:(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.ref' => 'value_const'
        }
      ]
    },
    'objectValue' => {
      '.all' => [
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\{(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.any' => [
            {
              '.all' => [
                {
                  '.ref' => 'objectField'
                },
                {
                  '+min' => 0,
                  '-flat' => 1,
                  '.all' => [
                    {
                      '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
                    },
                    {
                      '.ref' => 'objectField'
                    }
                  ]
                }
              ]
            },
            {
              '.err' => 'Expected name'
            }
          ]
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\}(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        }
      ]
    },
    'objectValue_const' => {
      '.all' => [
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\{(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.any' => [
            {
              '.all' => [
                {
                  '.ref' => 'objectField_const'
                },
                {
                  '+min' => 0,
                  '-flat' => 1,
                  '.all' => [
                    {
                      '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
                    },
                    {
                      '.ref' => 'objectField_const'
                    }
                  ]
                }
              ]
            },
            {
              '.err' => 'Expected name or constant'
            }
          ]
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\}(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        }
      ]
    },
    'operationDefinition' => {
      '.any' => [
        {
          '.ref' => 'selectionSet'
        },
        {
          '.all' => [
            {
              '.ref' => 'operationType'
            },
            {
              '.ref' => '_'
            },
            {
              '+max' => 1,
              '.ref' => 'name'
            },
            {
              '.ref' => '_'
            },
            {
              '+max' => 1,
              '.ref' => 'variableDefinitions'
            },
            {
              '.ref' => '_'
            },
            {
              '+max' => 1,
              '.ref' => 'directives'
            },
            {
              '.ref' => '_'
            },
            {
              '.ref' => 'selectionSet'
            }
          ]
        }
      ]
    },
    'operationType' => {
      '.rgx' => qr/\G(query|mutation|subscription)/
    },
    'operationTypeDefinition' => {
      '.all' => [
        {
          '.ref' => 'operationType'
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*:(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.ref' => 'namedType'
        },
        {
          '.ref' => '_'
        }
      ]
    },
    'scalar' => {
      '.all' => [
        {
          '.rgx' => qr/\Gscalar(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.ref' => 'name'
        },
        {
          '.ref' => '_'
        },
        {
          '+max' => 1,
          '.ref' => 'directives'
        }
      ]
    },
    'schema' => {
      '.all' => [
        {
          '.rgx' => qr/\Gschema(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '+max' => 1,
          '.ref' => 'directives'
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\{(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '+min' => 1,
          '.ref' => 'operationTypeDefinition'
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\}(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        }
      ]
    },
    'selection' => {
      '.any' => [
        {
          '.ref' => 'field'
        },
        {
          '.ref' => 'inline_fragment'
        },
        {
          '.ref' => 'fragment_spread'
        }
      ]
    },
    'selectionSet' => {
      '.all' => [
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\{(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.any' => [
            {
              '.all' => [
                {
                  '.ref' => 'selection'
                },
                {
                  '+min' => 0,
                  '-flat' => 1,
                  '.all' => [
                    {
                      '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
                    },
                    {
                      '.ref' => 'selection'
                    }
                  ]
                },
                {
                  '+max' => 1,
                  '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
                }
              ]
            },
            {
              '.err' => 'Expected name'
            }
          ]
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\}(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        }
      ]
    },
    'spread' => {
      '.all' => [
        {
          '.rgx' => qr/\G\.{3}/
        },
        {
          '.ref' => '_'
        }
      ]
    },
    'string' => {
      '.rgx' => qr/\G"((?:\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})|[^"\x00-\x1f\\])*)"/
    },
    'type' => {
      '.all' => [
        {
          '.rgx' => qr/\Gtype(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.ref' => 'name'
        },
        {
          '.ref' => '_'
        },
        {
          '+max' => 1,
          '.ref' => 'implementsInterfaces'
        },
        {
          '.ref' => '_'
        },
        {
          '+max' => 1,
          '.ref' => 'directives'
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\{(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '+min' => 0,
          '.ref' => 'fieldDefinition'
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\}(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        }
      ]
    },
    'typeCondition' => {
      '.all' => [
        {
          '.rgx' => qr/\Gon(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.ref' => 'namedType'
        }
      ]
    },
    'typeDefinition' => {
      '.any' => [
        {
          '.ref' => 'scalar'
        },
        {
          '.ref' => 'type'
        },
        {
          '.ref' => 'interface'
        },
        {
          '.ref' => 'union'
        },
        {
          '.ref' => 'enumTypeDefinition'
        },
        {
          '.ref' => 'input'
        }
      ]
    },
    'typeExtensionDefinition' => {
      '.all' => [
        {
          '.rgx' => qr/\Gextend(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.ref' => 'type'
        }
      ]
    },
    'typeSystemDefinition' => {
      '.all' => [
        {
          '.ref' => '_'
        },
        {
          '.any' => [
            {
              '.ref' => 'schema'
            },
            {
              '.ref' => 'typeDefinition'
            },
            {
              '.ref' => 'typeExtensionDefinition'
            },
            {
              '.ref' => 'directive'
            }
          ]
        },
        {
          '.ref' => '_'
        }
      ]
    },
    'typedef' => {
      '.any' => [
        {
          '.ref' => 'nonNullType'
        },
        {
          '.ref' => 'namedType'
        },
        {
          '.ref' => 'listType'
        }
      ]
    },
    'union' => {
      '.all' => [
        {
          '.rgx' => qr/\Gunion(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.ref' => 'name'
        },
        {
          '.ref' => '_'
        },
        {
          '+max' => 1,
          '.ref' => 'directives'
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*=(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.ref' => 'unionMembers'
        }
      ]
    },
    'unionMembers' => {
      '.all' => [
        {
          '.ref' => 'namedType'
        },
        {
          '+min' => 0,
          '-flat' => 1,
          '.all' => [
            {
              '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\|(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
            },
            {
              '.ref' => 'namedType'
            }
          ]
        }
      ]
    },
    'value' => {
      '.any' => [
        {
          '.ref' => 'variable'
        },
        {
          '.ref' => 'float'
        },
        {
          '.ref' => 'int'
        },
        {
          '.ref' => 'string'
        },
        {
          '.ref' => 'boolean'
        },
        {
          '.ref' => 'null'
        },
        {
          '.ref' => 'enumValue'
        },
        {
          '.ref' => 'listValue'
        },
        {
          '.ref' => 'objectValue'
        }
      ]
    },
    'value_const' => {
      '.any' => [
        {
          '.ref' => 'float'
        },
        {
          '.ref' => 'int'
        },
        {
          '.ref' => 'string'
        },
        {
          '.ref' => 'boolean'
        },
        {
          '.ref' => 'null'
        },
        {
          '.ref' => 'enumValue'
        },
        {
          '.ref' => 'listValue_const'
        },
        {
          '.ref' => 'objectValue_const'
        }
      ]
    },
    'variable' => {
      '.all' => [
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\$/u
        },
        {
          '.ref' => 'name'
        }
      ]
    },
    'variableDefinition' => {
      '.all' => [
        {
          '.ref' => 'variable'
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*:(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.ref' => 'typedef'
        },
        {
          '+max' => 1,
          '.ref' => 'defaultValue'
        }
      ]
    },
    'variableDefinitions' => {
      '.all' => [
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\((?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.all' => [
            {
              '.ref' => 'variableDefinition'
            },
            {
              '+min' => 0,
              '-flat' => 1,
              '.all' => [
                {
                  '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
                },
                {
                  '.ref' => 'variableDefinition'
                }
              ]
            }
          ]
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*\)(?:\s|\x{FEFF}|,|\#[\ \t]*[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        }
      ]
    }
  }
}

1;
