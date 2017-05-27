package GraphQL::Grammar;

use 5.014;
use strict;
use warnings;
use base 'Pegex::Grammar';
use constant file => './graphql.pgx';

=head1 NAME

GraphQL - Perl implementation

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
          '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*:(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
        }
      ]
    },
    'argument' => {
      '.all' => [
        {
          '.ref' => 'name'
        },
        {
          '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*:(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
        },
        {
          '.ref' => 'value'
        }
      ]
    },
    'arguments' => {
      '.all' => [
        {
          '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*\((?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
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
                  '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*,?(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
                },
                {
                  '.ref' => 'argument'
                }
              ]
            },
            {
              '+max' => 1,
              '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*,?(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
            }
          ]
        },
        {
          '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*\)(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
        }
      ]
    },
    'boolean' => {
      '.rgx' => qr/\G(true|false)/
    },
    'defaultValue' => {
      '.all' => [
        {
          '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*=(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
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
              '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
            },
            {
              '.ref' => 'operationDefinition'
            }
          ]
        },
        {
          '.all' => [
            {
              '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
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
          '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*\@/
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
          '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
        },
        {
          '+max' => 1,
          '.ref' => 'arguments'
        },
        {
          '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
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
    'fragmentDefinition' => {
      '.all' => [
        {
          '.rgx' => qr/\Gfragment/
        },
        {
          '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
        },
        {
          '.ref' => 'fragmentName'
        },
        {
          '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
        },
        {
          '.ref' => 'typeCondition'
        },
        {
          '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
        },
        {
          '+max' => 1,
          '.ref' => 'directives'
        },
        {
          '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
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
          '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
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
          '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
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
          '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
        },
        {
          '+max' => 1,
          '.ref' => 'directives'
        },
        {
          '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
        },
        {
          '.ref' => 'selectionSet'
        }
      ]
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
                  '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*,?(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
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
    'number' => {
      '.rgx' => qr/\G(\-?(?:0|[1-9][0-9]*)(?:\.[0-9]*)?(?:[eE][\-\+]?[0-9]+)?)/
    },
    'objectField' => {
      '.all' => [
        {
          '.ref' => 'name'
        },
        {
          '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*:(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
        },
        {
          '.ref' => 'value'
        }
      ]
    },
    'objectValue' => {
      '.all' => [
        {
          '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*\{(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
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
                  '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*,?(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
                },
                {
                  '.ref' => 'objectField'
                }
              ]
            }
          ]
        },
        {
          '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*\}(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
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
              '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
            },
            {
              '+max' => 1,
              '.ref' => 'name'
            },
            {
              '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
            },
            {
              '+max' => 1,
              '.ref' => 'variableDefinitions'
            },
            {
              '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
            },
            {
              '+max' => 1,
              '.ref' => 'directives'
            },
            {
              '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
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
          '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*\{(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
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
                  '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*,?(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
                },
                {
                  '.ref' => 'selection'
                }
              ]
            },
            {
              '+max' => 1,
              '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*,?(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
            }
          ]
        },
        {
          '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*\}(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
        }
      ]
    },
    'spread' => {
      '.all' => [
        {
          '.rgx' => qr/\G\.{3}/
        },
        {
          '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
        }
      ]
    },
    'string' => {
      '.rgx' => qr/\G"((?:\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})|[^"\x00-\x1f])*)"/
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
          '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
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
          '.ref' => 'number'
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
          '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*\$/
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
          '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*:(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
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
          '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*\((?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
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
                  '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*,?(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
                },
                {
                  '.ref' => 'variableDefinition'
                }
              ]
            }
          ]
        },
        {
          '.rgx' => qr/\G(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*\)(?:\s|\#[^\r\n]*(?:\r?\n|\r!NL|\z))*/
        }
      ]
    }
  }
}

=head1 NAME

GraphQL::Grammar - GraphQL Pegex grammar class

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

=head1 METHODS

=head2 parse

  GraphQL::Language->parse($source, $noLocation);

=cut

1;
