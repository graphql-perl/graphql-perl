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

sub make_tree {   # Generated/Inlined by Pegex::Grammar (0.70)
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
      '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
    },
    'alias' => {
      '.all' => [
        {
          '.ref' => 'name'
        },
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*:(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
        }
      ]
    },
    'argument' => {
      '.all' => [
        {
          '.ref' => 'name'
        },
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*:(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
        },
        {
          '.ref' => 'value'
        }
      ]
    },
    'arguments' => {
      '.all' => [
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*\((?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
        },
        {
          '+min' => 1,
          '.ref' => 'argument'
        },
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*\)(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
        }
      ]
    },
    'argumentsDefinition' => {
      '.all' => [
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*\(/
        },
        {
          '+min' => 1,
          '.ref' => 'inputValueDefinition'
        },
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*\)/
        }
      ]
    },
    'blockStringValue' => {
      '.rgx' => qr/\G"""((?:(?:\\""")|[^\x00-\x1f"]|[\t\n\r]|(?:"(?!"")))*)"""/
    },
    'boolean' => {
      '.rgx' => qr/\G(true|false)/
    },
    'comment' => {
      '.rgx' => qr/\G[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z)/
    },
    'defaultValue' => {
      '.all' => [
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*=(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
        },
        {
          '.ref' => 'value_const'
        }
      ]
    },
    'definition' => {
      '.any' => [
        {
          '.ref' => 'operationDefinition'
        },
        {
          '.ref' => 'fragment'
        },
        {
          '.ref' => 'typeSystemDefinition'
        },
        {
          '-skip' => 1,
          '.ref' => 'ws2'
        }
      ]
    },
    'description' => {
      '.any' => [
        {
          '.all' => [
            {
              '-skip' => 1,
              '.rgx' => qr/\G[\s\n]*/
            },
            {
              '.any' => [
                {
                  '+min' => 1,
                  '.ref' => 'comment'
                },
                {
                  '.ref' => 'string'
                }
              ]
            },
            {
              '-skip' => 1,
              '.rgx' => qr/\G[\s\n]*/
            }
          ]
        },
        {
          '-skip' => 1,
          '.ref' => '_'
        }
      ]
    },
    'directive' => {
      '.all' => [
        {
          '-skip' => 1,
          '.rgx' => qr/\Gdirective(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*\@(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
        },
        {
          '.ref' => 'name'
        },
        {
          '-skip' => 1,
          '.ref' => '_'
        },
        {
          '+max' => 1,
          '.ref' => 'argumentsDefinition'
        },
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*on(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
        },
        {
          '.ref' => 'directiveLocations'
        }
      ]
    },
    'directiveLocations' => {
      '.all' => [
        {
          '+max' => 1,
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*\|(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
        },
        {
          '.all' => [
            {
              '.ref' => 'name'
            },
            {
              '+min' => 0,
              '-flat' => 1,
              '.all' => [
                {
                  '-skip' => 1,
                  '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*\|(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
                },
                {
                  '.ref' => 'name'
                }
              ]
            }
          ]
        }
      ]
    },
    'directiveactual' => {
      '.all' => [
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*\@/
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
          '-skip' => 1,
          '.rgx' => qr/\Genum(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
        },
        {
          '.ref' => 'name'
        },
        {
          '-skip' => 1,
          '.ref' => '_'
        },
        {
          '+max' => 1,
          '.ref' => 'directives'
        },
        {
          '+max' => 1,
          '.all' => [
            {
              '-skip' => 1,
              '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*\{/
            },
            {
              '+min' => 1,
              '.ref' => 'enumValueDefinition'
            },
            {
              '-skip' => 1,
              '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*\}/
            }
          ]
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
          '+max' => 1,
          '.ref' => 'description'
        },
        {
          '.ref' => 'enumValue'
        },
        {
          '+max' => 1,
          '.all' => [
            {
              '-skip' => 1,
              '.ref' => '_'
            },
            {
              '.ref' => 'directives'
            }
          ]
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
          '-skip' => 1,
          '.ref' => '_'
        },
        {
          '+max' => 1,
          '.ref' => 'arguments'
        },
        {
          '-skip' => 1,
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
          '+max' => 1,
          '.ref' => 'description'
        },
        {
          '.ref' => 'name'
        },
        {
          '-skip' => 1,
          '.ref' => '_'
        },
        {
          '+max' => 1,
          '.ref' => 'argumentsDefinition'
        },
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*:(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
        },
        {
          '.ref' => 'typedef'
        },
        {
          '-skip' => 1,
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
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*fragment(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
        },
        {
          '.ref' => 'fragmentName'
        },
        {
          '-skip' => 1,
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
          '-skip' => 1,
          '.ref' => '_'
        },
        {
          '+max' => 1,
          '.ref' => 'directives'
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
          '-skip' => 1,
          '.ref' => '_'
        },
        {
          '+max' => 1,
          '.ref' => 'directives'
        }
      ]
    },
    'graphql' => {
      '+min' => 1,
      '.ref' => 'definition'
    },
    'implementsInterfaces' => {
      '.all' => [
        {
          '-skip' => 1,
          '.rgx' => qr/\Gimplements(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
        },
        {
          '+max' => 1,
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*&(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
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
                  '-skip' => 1,
                  '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*&(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
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
          '-skip' => 1,
          '.ref' => '_'
        },
        {
          '+max' => 1,
          '.ref' => 'directives'
        },
        {
          '.ref' => 'selectionSet'
        }
      ]
    },
    'input' => {
      '.all' => [
        {
          '-skip' => 1,
          '.rgx' => qr/\Ginput(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
        },
        {
          '.ref' => 'name'
        },
        {
          '-skip' => 1,
          '.ref' => '_'
        },
        {
          '+max' => 1,
          '.ref' => 'directives'
        },
        {
          '+max' => 1,
          '.all' => [
            {
              '-skip' => 1,
              '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*\{/
            },
            {
              '+min' => 1,
              '.ref' => 'inputValueDefinition'
            },
            {
              '-skip' => 1,
              '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*\}/
            }
          ]
        }
      ]
    },
    'inputValueDefinition' => {
      '.all' => [
        {
          '+max' => 1,
          '.ref' => 'description'
        },
        {
          '.ref' => 'name'
        },
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*:(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
        },
        {
          '.ref' => 'typedef'
        },
        {
          '-skip' => 1,
          '.ref' => '_'
        },
        {
          '+max' => 1,
          '.ref' => 'defaultValue'
        },
        {
          '-skip' => 1,
          '.ref' => '_'
        },
        {
          '+max' => 1,
          '.ref' => 'directives'
        },
        {
          '-skip' => 1,
          '.ref' => '_'
        }
      ]
    },
    'int' => {
      '.rgx' => qr/\G(\-?(?:0|[1-9][0-9]*))/
    },
    'interface' => {
      '.all' => [
        {
          '-skip' => 1,
          '.rgx' => qr/\Ginterface(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
        },
        {
          '.ref' => 'name'
        },
        {
          '-skip' => 1,
          '.ref' => '_'
        },
        {
          '+max' => 1,
          '.ref' => 'directives'
        },
        {
          '+max' => 1,
          '.all' => [
            {
              '-skip' => 1,
              '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*\{/
            },
            {
              '+min' => 1,
              '.ref' => 'fieldDefinition'
            },
            {
              '-skip' => 1,
              '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*\}/
            }
          ]
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
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*\[(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
        },
        {
          '+min' => 0,
          '.ref' => 'value'
        },
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*\](?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
        }
      ]
    },
    'listValue_const' => {
      '.all' => [
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*\[(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
        },
        {
          '+min' => 0,
          '.ref' => 'value_const'
        },
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*\](?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
        }
      ]
    },
    'name' => {
      '.rgx' => qr/\G([_a-zA-Z][0-9A-Za-z_]*)/
    },
    'namedType' => {
      '.all' => [
        {
          '.ref' => 'name'
        },
        {
          '-skip' => 1,
          '.ref' => '_'
        }
      ]
    },
    'nonNullType' => {
      '.any' => [
        {
          '.all' => [
            {
              '.ref' => 'namedType'
            },
            {
              '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*!/
            }
          ]
        },
        {
          '.all' => [
            {
              '.ref' => 'listType'
            },
            {
              '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*!/
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
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*:(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
        },
        {
          '.ref' => 'value'
        },
        {
          '-skip' => 1,
          '.ref' => '_'
        }
      ]
    },
    'objectField_const' => {
      '.all' => [
        {
          '.ref' => 'name'
        },
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*:(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
        },
        {
          '.ref' => 'value_const'
        }
      ]
    },
    'objectValue' => {
      '.all' => [
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*\{(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
        },
        {
          '.any' => [
            {
              '+min' => 1,
              '.ref' => 'objectField'
            },
            {
              '.err' => 'Expected name'
            }
          ]
        },
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*\}(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
        }
      ]
    },
    'objectValue_const' => {
      '.all' => [
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*\{(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
        },
        {
          '.any' => [
            {
              '+min' => 1,
              '.ref' => 'objectField_const'
            },
            {
              '.err' => 'Expected name or constant'
            }
          ]
        },
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*\}(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
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
              '-skip' => 1,
              '.ref' => '_'
            },
            {
              '+max' => 1,
              '.ref' => 'name'
            },
            {
              '-skip' => 1,
              '.ref' => '_'
            },
            {
              '+max' => 1,
              '.ref' => 'variableDefinitions'
            },
            {
              '-skip' => 1,
              '.ref' => '_'
            },
            {
              '+max' => 1,
              '.ref' => 'directives'
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
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*:(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
        },
        {
          '.ref' => 'namedType'
        },
        {
          '-skip' => 1,
          '.ref' => '_'
        }
      ]
    },
    'scalar' => {
      '.all' => [
        {
          '-skip' => 1,
          '.rgx' => qr/\Gscalar(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
        },
        {
          '.ref' => 'name'
        },
        {
          '-skip' => 1,
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
          '-skip' => 1,
          '.rgx' => qr/\Gschema(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
        },
        {
          '+max' => 1,
          '.ref' => 'directives'
        },
        {
          '+max' => 1,
          '.all' => [
            {
              '-skip' => 1,
              '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*\{(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
            },
            {
              '+min' => 1,
              '.ref' => 'operationTypeDefinition'
            },
            {
              '-skip' => 1,
              '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*\}/
            }
          ]
        }
      ]
    },
    'selection' => {
      '.all' => [
        {
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
        {
          '-skip' => 1,
          '.ref' => '_'
        }
      ]
    },
    'selectionSet' => {
      '.all' => [
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*\{(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
        },
        {
          '.any' => [
            {
              '+min' => 1,
              '.ref' => 'selection'
            },
            {
              '.err' => 'Expected name'
            }
          ]
        },
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*\}(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
        }
      ]
    },
    'spread' => {
      '.all' => [
        {
          '.rgx' => qr/\G\.{3}/
        },
        {
          '-skip' => 1,
          '.ref' => '_'
        }
      ]
    },
    'string' => {
      '.any' => [
        {
          '.ref' => 'blockStringValue'
        },
        {
          '.ref' => 'stringValue'
        }
      ]
    },
    'stringValue' => {
      '.rgx' => qr/\G"((?:\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})|[^"\x00-\x1f\\])*)"/
    },
    'type' => {
      '.all' => [
        {
          '-skip' => 1,
          '.rgx' => qr/\Gtype(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
        },
        {
          '.ref' => 'name'
        },
        {
          '-skip' => 1,
          '.ref' => '_'
        },
        {
          '+max' => 1,
          '.ref' => 'implementsInterfaces'
        },
        {
          '-skip' => 1,
          '.ref' => '_'
        },
        {
          '+max' => 1,
          '.ref' => 'directives'
        },
        {
          '+max' => 1,
          '.all' => [
            {
              '-skip' => 1,
              '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*\{/
            },
            {
              '+min' => 1,
              '.ref' => 'fieldDefinition'
            },
            {
              '-skip' => 1,
              '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*\}/
            }
          ]
        }
      ]
    },
    'typeCondition' => {
      '.all' => [
        {
          '-skip' => 1,
          '.rgx' => qr/\Gon(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
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
          '-skip' => 1,
          '.rgx' => qr/\Gextend(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
        },
        {
          '.any' => [
            {
              '.ref' => 'schema'
            },
            {
              '.ref' => 'typeDefinition'
            }
          ]
        }
      ]
    },
    'typeSystemDefinition' => {
      '.all' => [
        {
          '+max' => 1,
          '.ref' => 'description'
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
          '-skip' => 1,
          '.rgx' => qr/\Gunion(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
        },
        {
          '.ref' => 'name'
        },
        {
          '-skip' => 1,
          '.ref' => '_'
        },
        {
          '+max' => 1,
          '.ref' => 'directives'
        },
        {
          '+max' => 1,
          '.all' => [
            {
              '-skip' => 1,
              '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*=(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
            },
            {
              '.ref' => 'unionMembers'
            }
          ]
        }
      ]
    },
    'unionMembers' => {
      '.all' => [
        {
          '+max' => 1,
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*\|(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
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
                  '-skip' => 1,
                  '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*\|(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
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
    'value' => {
      '.all' => [
        {
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
        {
          '-skip' => 1,
          '.ref' => '_'
        }
      ]
    },
    'value_const' => {
      '.all' => [
        {
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
        {
          '-skip' => 1,
          '.ref' => '_'
        }
      ]
    },
    'variable' => {
      '.all' => [
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*\$/
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
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*:(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
        },
        {
          '.ref' => 'typedef'
        },
        {
          '+max' => 1,
          '.ref' => 'defaultValue'
        },
        {
          '-skip' => 1,
          '.ref' => '_'
        }
      ]
    },
    'variableDefinitions' => {
      '.all' => [
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*\((?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
        },
        {
          '+min' => 1,
          '.ref' => 'variableDefinition'
        },
        {
          '-skip' => 1,
          '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*\)(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))*/
        }
      ]
    },
    'ws2' => {
      '.rgx' => qr/\G(?:\s|\x{FEFF}|,|[\ \t]*\#[\ \t]*([^\r\n]*)(?:\r?\n|\r!NL|\z))+/
    }
  }
}

1;
