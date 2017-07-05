package GraphQL::Grammar;

use 5.014;
use strict;
use warnings;
use base 'Pegex::Grammar';
use constant file => './graphql.pgx';

our $VERSION = '0.05';

=head1 NAME

GraphQL::Grammar - GraphQL grammar

=head1 SYNOPSIS

  use Pegex::Parser;
  use GraphQL::Grammar;
  use Pegex::Tree::Wrap;
  use Pegex::Input;

  my $parser = Pegex::Parser->new(
    grammar => GraphQL::Grammar->new,
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

sub make_tree {   # Generated/Inlined by Pegex::Grammar (0.60)
  {
    '+grammar' => 'graphql',
    '+include' => 'pegex-atoms',
    '+toprule' => 'graphql',
    '+version' => '0.01',
    'BANG' => {
      '.rgx' => qr/\G!/
    },
    'LSQUARE' => {
      '.rgx' => qr/\G\[/
    },
    'RSQUARE' => {
      '.rgx' => qr/\G\]/
    },
    'alias' => {
      '.all' => [
        {
          '.ref' => 'name'
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*:(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        }
      ]
    },
    'argument' => {
      '.all' => [
        {
          '.ref' => 'name'
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*:(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.ref' => 'value'
        }
      ]
    },
    'arguments' => {
      '.all' => [
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*\((?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
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
                  '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*,?(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
                },
                {
                  '.ref' => 'argument'
                }
              ]
            },
            {
              '+max' => 1,
              '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*,?(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
            }
          ]
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*\)(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        }
      ]
    },
    'boolean' => {
      '.rgx' => qr/\G(true|false)/
    },
    'defaultValue' => {
      '.all' => [
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*=(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.ref' => 'value'
        }
      ]
    },
    'definition' => {
      '.any' => [
        {
          '.all' => [
            {
              '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
            },
            {
              '.ref' => 'operationDefinition'
            }
          ]
        },
        {
          '.all' => [
            {
              '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
            },
            {
              '.ref' => 'fragmentDefinition'
            }
          ]
        }
      ]
    },
    'directive' => {
      '.all' => [
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*\@/u
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
      '.ref' => 'directive'
    },
    'enumValue' => {
      '.ref' => 'name'
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
          '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '+max' => 1,
          '.ref' => 'arguments'
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
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
    'float' => {
      '.rgx' => qr/\G(\-?(?:0|[1-9][0-9]*)(?:(?:\.[0-9]+)(?:[eE][\-\+]?[0-9]+)|(?:\.[0-9]+)|(?:[eE][\-\+]?[0-9]+)))/
    },
    'fragmentDefinition' => {
      '.all' => [
        {
          '.rgx' => qr/\Gfragment/
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.ref' => 'fragmentName'
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.ref' => 'typeCondition'
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '+max' => 1,
          '.ref' => 'directives'
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.ref' => 'selectionSet'
        }
      ]
    },
    'fragmentName' => {
      '.ref' => 'name'
    },
    'fragmentSpread' => {
      '.all' => [
        {
          '-skip' => 1,
          '.ref' => 'spread'
        },
        {
          '.ref' => 'fragmentName'
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
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
          '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '+min' => 1,
          '.ref' => 'definition'
        }
      ]
    },
    'inlineFragment' => {
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
          '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '+max' => 1,
          '.ref' => 'directives'
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.ref' => 'selectionSet'
        }
      ]
    },
    'int' => {
      '.rgx' => qr/\G(\-?(?:0|[1-9][0-9]*))/
    },
    'listType' => {
      '.all' => [
        {
          '.ref' => 'LSQUARE'
        },
        {
          '.ref' => 'type'
        },
        {
          '.ref' => 'RSQUARE'
        }
      ]
    },
    'listValue' => {
      '.all' => [
        {
          '.ref' => 'LSQUARE'
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
                  '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*,?(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
                },
                {
                  '.ref' => 'value'
                }
              ]
            }
          ]
        },
        {
          '.ref' => 'RSQUARE'
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
      '.ref' => 'BANG'
    },
    'null' => {
      '.rgx' => qr/\Gnull/
    },
    'objectField' => {
      '.all' => [
        {
          '.ref' => 'name'
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*:(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.ref' => 'value'
        }
      ]
    },
    'objectValue' => {
      '.all' => [
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*\{(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
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
                  '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*,?(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
                },
                {
                  '.ref' => 'objectField'
                }
              ]
            }
          ]
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*\}(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
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
              '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
            },
            {
              '+max' => 1,
              '.ref' => 'name'
            },
            {
              '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
            },
            {
              '+max' => 1,
              '.ref' => 'variableDefinitions'
            },
            {
              '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
            },
            {
              '+max' => 1,
              '.ref' => 'directives'
            },
            {
              '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
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
    'selection' => {
      '.any' => [
        {
          '.ref' => 'field'
        },
        {
          '.ref' => 'inlineFragment'
        },
        {
          '.ref' => 'fragmentSpread'
        }
      ]
    },
    'selectionSet' => {
      '.all' => [
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*\{(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
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
                  '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*,?(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
                },
                {
                  '.ref' => 'selection'
                }
              ]
            },
            {
              '+max' => 1,
              '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*,?(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
            }
          ]
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*\}(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        }
      ]
    },
    'spread' => {
      '.all' => [
        {
          '.rgx' => qr/\G\.{3}/
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        }
      ]
    },
    'string' => {
      '.rgx' => qr/\G"((?:\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})|[^"\x00-\x1f\\])*)"/
    },
    'type' => {
      '.any' => [
        {
          '.all' => [
            {
              '.ref' => 'namedType'
            },
            {
              '+max' => 1,
              '.ref' => 'nonNullType'
            }
          ]
        },
        {
          '.all' => [
            {
              '.ref' => 'listType'
            },
            {
              '+max' => 1,
              '.ref' => 'nonNullType'
            }
          ]
        }
      ]
    },
    'typeCondition' => {
      '.all' => [
        {
          '.rgx' => qr/\Gon/
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.ref' => 'namedType'
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
    'variable' => {
      '.all' => [
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*\$/u
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
          '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*:(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        },
        {
          '.ref' => 'type'
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
          '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*\((?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
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
                  '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*,?(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
                },
                {
                  '.ref' => 'variableDefinition'
                }
              ]
            }
          ]
        },
        {
          '.rgx' => qr/\G(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*\)(?:\s|\x{FEFF}|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/u
        }
      ]
    }
  }
}

1;
