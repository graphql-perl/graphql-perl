use 5.014;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Deep;
use JSON::MaybeXS;
use Data::Dumper;

my $JSON = JSON::MaybeXS->new->allow_nonref;

BEGIN {
  use_ok( 'GraphQL::Schema' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Object' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::InputObject' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Scalar', qw($String) ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Enum' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Introspection', '$QUERY' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Execution' ) || print "Bail out!\n";
}

sub run_test {
  my ($args, $expected) = @_;
  my $got = GraphQL::Execution->execute(@$args);
  is_deeply $got, $expected or diag nice_dump($got);
}

sub nice_dump {
  my ($got) = @_;
  local ($Data::Dumper::Sortkeys, $Data::Dumper::Indent, $Data::Dumper::Terse);
  $Data::Dumper::Sortkeys = $Data::Dumper::Indent = $Data::Dumper::Terse = 1;
  Dumper $got;
}

subtest 'executes an introspection query', sub {
  my $schema = GraphQL::Schema->new(query => GraphQL::Type::Object->new(
    name => 'QueryRoot',
    fields => { onlyField => { type => $String } },
  ));
  my $got = GraphQL::Execution->execute($schema, $QUERY, undef, undef, undef, 'IntrospectionQuery');
  my $expected_text = join '', <DATA>;
  $expected_text =~ s#bless\(\s*do\{\\\(my\s*\$o\s*=\s*(.)\)\},\s*'JSON::PP::Boolean'\s*\)#'JSON->' . ($1 ? 'true' : 'false')#ge;
  my $big_expected = eval 'use JSON::MaybeXS;my '.$expected_text.';$VAR1';
  local ($Data::Dumper::Sortkeys, $Data::Dumper::Indent, $Data::Dumper::Terse, $Data::Dumper::Purity);
  $Data::Dumper::Sortkeys = $Data::Dumper::Indent = $Data::Dumper::Terse = $Data::Dumper::Purity = 1;
  #open my $fh, '>', 'tf'; print $fh Dumper $got; # uncomment to regenerate
  $Data::Dumper::Purity = 0; # makes debug dumps less readable if 1
  is_deeply $got, $big_expected or diag Dumper $got;
  done_testing;
};

subtest 'introspects on input object'=> sub {
  my $TestInputObject = GraphQL::Type::InputObject->new(
    name => 'TestInputObject',
    fields => {
      a => { type => $String, default_value => 'foo' },
      b => { type => $String->list },
      c => { type => $String, default_value => undef }
    }
  );

  my $TestType = GraphQL::Type::Object->new(
    name => 'TestType',
    fields => {
      field => {
        type => $String,
        args => { complex => { type => $TestInputObject } },
        resolve => sub {
          my (undef, $args) = @_;
          return $JSON->encode($args->{complex});
        },
      }
    }
  );

  my $schema = GraphQL::Schema->new(query => $TestType);
  my $request = <<'EOQ';
{
  __schema {
    types {
      kind
      name
      inputFields {
        name
        type { ...TypeRef }
        defaultValue
      }
    }
  }
}

fragment TypeRef on __Type {
  kind
  name
  ofType {
    kind
    name
    ofType {
      kind
      name
      ofType {
        kind
        name
      }
    }
  }
}
EOQ

  my $got = GraphQL::Execution->execute($schema, $request);
  cmp_deeply $got, {
    data => {
      __schema => {
        types => supersetof(
          {
            kind => 'INPUT_OBJECT',
            name => 'TestInputObject',
            inputFields => bag(
              {
                name => 'a',
                type => {
                  kind => 'SCALAR',
                  name => 'String',
                  ofType => undef,
                },
                defaultValue => '"foo"',
              },
              {
                name => 'b',
                type => {
                  kind => 'LIST',
                  name => undef,
                  ofType => {
                    kind => 'SCALAR',
                    name => 'String',
                    ofType => undef,
                  }
                },
                defaultValue => undef,
              },
              {
                name => 'c',
                type => {
                  kind => 'SCALAR',
                  name => 'String',
                  ofType => undef,
                },
                defaultValue => undef,
              }
            )
          }
        )
      }
    }
  } or diag nice_dump($got);
};

subtest 'supports the __type root field'=> sub {
  my $TestType = GraphQL::Type::Object->new(
    name => 'TestType',
    fields => {
      testField => {
        type => $String,
      }
    }
  );

  my $schema = GraphQL::Schema->new(query => $TestType);
  my $request = <<'EOQ';
{
  __type(name: "TestType") {
    name
  }
}
EOQ

  run_test([$schema, $request], {
    data => { __type => { name => 'TestType' } }
  });
};

subtest 'identifies deprecated fields'=> sub {
  my $TestType = GraphQL::Type::Object->new(
    name => 'TestType',
    fields => {
      nonDeprecated => {
        type => $String,
      },
      deprecated => {
        type => $String,
        deprecation_reason => 'Removed in 1.0'
      }
    }
  );

  my $schema = GraphQL::Schema->new(query => $TestType);
  my $request = <<'EOQ';
{
  __type(name: "TestType") {
    name
    fields(includeDeprecated: true) {
      name
      isDeprecated,
      deprecationReason
    }
  }
}
EOQ

  run_test([$schema, $request], {
    data => {
      __type => {
        name => 'TestType',
        fields => [
          {
            name => 'deprecated',
            isDeprecated => JSON->true,
            deprecationReason => 'Removed in 1.0'
          },
          {
            name => 'nonDeprecated',
            isDeprecated => JSON->false,
            deprecationReason => undef,
          },
        ]
      }
    }
  });
};

subtest 'respects the includeDeprecated parameter for fields'=> sub {
  my $TestType = GraphQL::Type::Object->new(
    name => 'TestType',
    fields => {
      nonDeprecated => {
        type => $String,
      },
      deprecated => {
        type => $String,
        deprecation_reason => 'Removed in 1.0'
      }
    }
  );

  my $schema = GraphQL::Schema->new(query => $TestType);
  my $request = <<'EOQ';
{
  __type(name: "TestType") {
    name
    trueFields: fields(includeDeprecated: true) {
      name
    }
    falseFields: fields(includeDeprecated: false) {
      name
    }
    omittedFields: fields {
      name
    }
  }
}
EOQ

  run_test([$schema, $request], {
    data => {
      __type => {
        name => 'TestType',
        trueFields => [
          { name => 'deprecated' },
          { name => 'nonDeprecated' },
        ],
        falseFields => [
          { name => 'nonDeprecated' },
        ],
        omittedFields => [
          { name => 'nonDeprecated' },
        ],
      }
    }
  });
};

subtest 'identifies deprecated enum values'=> sub {
  my $TestEnum = GraphQL::Type::Enum->new(
    name => 'TestEnum',
    values => {
      NONDEPRECATED => { value => 0 },
      DEPRECATED => { value => 1, deprecation_reason => 'Removed in 1.0' },
      ALSONONDEPRECATED => { value => 2 }
    }
  );

  my $TestType = GraphQL::Type::Object->new(
    name => 'TestType',
    fields => {
      testEnum => {
        type => $TestEnum,
      },
    }
  );

  my $schema = GraphQL::Schema->new(query => $TestType);
  my $request = <<'EOQ';
{
  __type(name: "TestEnum") {
    name
    enumValues(includeDeprecated: true) {
      name
      isDeprecated,
      deprecationReason
    }
  }
}
EOQ

  run_test([$schema, $request], {
    data => {
      __type => {
        name => 'TestEnum',
        enumValues => [
          {
            name => 'ALSONONDEPRECATED',
            isDeprecated => JSON->false,
            deprecationReason => undef,
          },
          {
            name => 'DEPRECATED',
            isDeprecated => JSON->true,
            deprecationReason => 'Removed in 1.0',
          },
          {
            name => 'NONDEPRECATED',
            isDeprecated => JSON->false,
            deprecationReason => undef,
          },
        ]
      }
    }
  });
};

subtest 'respects the includeDeprecated parameter for enum values'=> sub {
  my $TestEnum = GraphQL::Type::Enum->new(
    name => 'TestEnum',
    values => {
      NONDEPRECATED => { value => 0 },
      DEPRECATED => { value => 1, deprecation_reason => 'Removed in 1.0' },
      ALSONONDEPRECATED => { value => 2 }
    }
  );

  my $TestType = GraphQL::Type::Object->new(
    name => 'TestType',
    fields => {
      testEnum => {
        type => $TestEnum,
      },
    }
  );

  my $schema = GraphQL::Schema->new(query => $TestType);
  my $request = <<'EOQ';
{
  __type(name: "TestEnum") {
    name
    trueValues: enumValues(includeDeprecated: true) {
      name
    }
    falseValues: enumValues(includeDeprecated: false) {
      name
    }
    omittedValues: enumValues {
      name
    }
  }
}
EOQ

  run_test([$schema, $request], {
    data => {
      __type => {
        name => 'TestEnum',
        trueValues => [
          { name => 'ALSONONDEPRECATED' },
          { name => 'DEPRECATED' },
          { name => 'NONDEPRECATED', },
        ],
        falseValues => [
          { name => 'ALSONONDEPRECATED' },
          { name => 'NONDEPRECATED' },
        ],
        omittedValues => [
          { name => 'ALSONONDEPRECATED' },
          { name => 'NONDEPRECATED' },
        ],
      }
    }
  });
};

subtest 'fails as expected on the __type root field without an arg'=> sub {
  my $TestType = GraphQL::Type::Object->new(
    name => 'TestType',
    fields => {
      testField => {
        type => $String,
      }
    }
  );

  my $schema = GraphQL::Schema->new(query => $TestType);
  my $request = <<'EOQ';
{
  __type {
    name
  }
}
EOQ

  my $got = GraphQL::Execution->execute($schema, $request);
  cmp_deeply $got, {
    data => { __type => undef },
    errors => [noclass(superhashof({
      message => 'Argument \'name\' of type \'String!\' not given.',
      locations => [{ line => 5, column => 1 }],
    }))]
  } or diag nice_dump($got);
};

subtest 'exposes descriptions on types and fields'=> sub {
  my $QueryRoot = GraphQL::Type::Object->new(
    name => 'QueryRoot',
    fields => {
      onlyField => { type => $String }
    }
  );

  my $schema = GraphQL::Schema->new(query => $QueryRoot);
  my $request = <<'EOQ';
{
  schemaType: __type(name: "__Schema") {
    name,
    description,
    fields {
      name,
      description
    }
  }
}
EOQ

  my $got = GraphQL::Execution->execute($schema, $request);
  cmp_deeply $got, {
    data => {
      schemaType => {
        name => '__Schema',
        description => 'A GraphQL Schema defines the capabilities of a GraphQL server. It exposes all available types and directives on the server, as well as the entry points for query, mutation, and subscription operations.',
        fields => bag(
          {
            name => 'types',
            description => 'A list of all types supported by this server.'
          },
          {
            name => 'queryType',
            description => 'The type that query operations will be rooted at.'
          },
          {
            name => 'mutationType',
            description => 'If this server supports mutation, the type that mutation operations will be rooted at.'
          },
          {
            name => 'subscriptionType',
            description => 'If this server support subscription, the type that subscription operations will be rooted at.',
          },
          {
            name => 'directives',
            description => 'A list of all directives supported by this server.'
          }
        )
      }
    }
  } or diag nice_dump($got);
};

subtest 'exposes descriptions on enums'=> sub {
  my $QueryRoot = GraphQL::Type::Object->new(
    name => 'QueryRoot',
    fields => {
      onlyField => { type => $String }
    }
  );

  my $schema = GraphQL::Schema->new(query => $QueryRoot);
  my $request = <<'EOQ';
{
  typeKindType: __type(name: "__TypeKind") {
    name,
    description,
    enumValues {
      name,
      description
    }
  }
}
EOQ

  my $got = GraphQL::Execution->execute($schema, $request);
  cmp_deeply $got, {
    data => {
      typeKindType => {
        name => '__TypeKind',
        description => 'An enum describing what kind of type a given `__Type` is.',
        enumValues => bag(
          {
            description => 'Indicates this type is a scalar.',
            name => 'SCALAR'
          },
          {
            description => 'Indicates this type is an object. `fields` and `interfaces` are valid fields.',
            name => 'OBJECT'
          },
          {
            description => 'Indicates this type is an interface. `fields` and `possibleTypes` are valid fields.',
            name => 'INTERFACE'
          },
          {
            description => 'Indicates this type is a union. `possibleTypes` is a valid field.',
            name => 'UNION'
          },
          {
            description => 'Indicates this type is an enum. `enumValues` is a valid field.',
            name => 'ENUM'
          },
          {
            description => 'Indicates this type is an input object. `inputFields` is a valid field.',
            name => 'INPUT_OBJECT'
          },
          {
            description => 'Indicates this type is a list. `ofType` is a valid field.',
            name => 'LIST'
          },
          {
            description => 'Indicates this type is a non-null. `ofType` is a valid field.',
            name => 'NON_NULL'
          }
        )
      }
    }
  } or diag nice_dump($got);
};

done_testing;

__DATA__
$VAR1 = {
  'data' => {
    '__schema' => {
      'directives' => [
        {
          'args' => [
            {
              'defaultValue' => undef,
              'description' => 'Included when true.',
              'name' => 'if',
              'type' => {
                'kind' => 'NON_NULL',
                'name' => undef,
                'ofType' => {
                  'kind' => 'SCALAR',
                  'name' => 'Boolean',
                  'ofType' => undef
                }
              }
            }
          ],
          'description' => 'Directs the executor to include this field or fragment only when the `if` argument is true.',
          'locations' => [
            'FIELD',
            'FRAGMENT_SPREAD',
            'INLINE_FRAGMENT'
          ],
          'name' => 'include'
        },
        {
          'args' => [
            {
              'defaultValue' => undef,
              'description' => 'Skipped when true.',
              'name' => 'if',
              'type' => {
                'kind' => 'NON_NULL',
                'name' => undef,
                'ofType' => {
                  'kind' => 'SCALAR',
                  'name' => 'Boolean',
                  'ofType' => undef
                }
              }
            }
          ],
          'description' => 'Directs the executor to skip this field or fragment when the `if` argument is true.',
          'locations' => [
            'FIELD',
            'FRAGMENT_SPREAD',
            'INLINE_FRAGMENT'
          ],
          'name' => 'skip'
        },
        {
          'args' => [
            {
              'defaultValue' => '"No longer supported"',
              'description' => 'Explains why this element was deprecated, usually also including a suggestion for how to access supported similar data. Formatted in [Markdown](https://daringfireball.net/projects/markdown/).',
              'name' => 'reason',
              'type' => {
                'kind' => 'SCALAR',
                'name' => 'String',
                'ofType' => undef
              }
            }
          ],
          'description' => 'Marks an element of a GraphQL schema as no longer supported.',
          'locations' => [
            'FIELD_DEFINITION',
            'ENUM_VALUE'
          ],
          'name' => 'deprecated'
        }
      ],
      'mutationType' => undef,
      'queryType' => {
        'name' => 'QueryRoot'
      },
      'subscriptionType' => undef,
      'types' => [
        {
          'description' => 'The `Boolean` scalar type represents `true` or `false`.',
          'enumValues' => undef,
          'fields' => undef,
          'inputFields' => undef,
          'interfaces' => undef,
          'kind' => 'SCALAR',
          'name' => 'Boolean',
          'possibleTypes' => undef
        },
        {
          'description' => undef,
          'enumValues' => undef,
          'fields' => [
            {
              'args' => [],
              'deprecationReason' => undef,
              'description' => undef,
              'isDeprecated' => bless( do{\(my $o = 0)}, 'JSON::PP::Boolean' ),
              'name' => 'onlyField',
              'type' => {
                'kind' => 'SCALAR',
                'name' => 'String',
                'ofType' => undef
              }
            }
          ],
          'inputFields' => undef,
          'interfaces' => [],
          'kind' => 'OBJECT',
          'name' => 'QueryRoot',
          'possibleTypes' => undef
        },
        {
          'description' => 'The `String` scalar type represents textual data, represented as UTF-8 character sequences. The String type is most often used by GraphQL to represent free-form human-readable text.',
          'enumValues' => undef,
          'fields' => undef,
          'inputFields' => undef,
          'interfaces' => undef,
          'kind' => 'SCALAR',
          'name' => 'String',
          'possibleTypes' => undef
        },
        {
          'description' => 'A Directive provides a way to describe alternate runtime execution and type validation behavior in a GraphQL document.

In some cases, you need to provide options to alter GraphQL\'s execution behavior in ways field arguments will not suffice, such as conditionally including or skipping a field. Directives provide this by describing additional information to the executor.',
          'enumValues' => undef,
          'fields' => [
            {
              'args' => [],
              'deprecationReason' => undef,
              'description' => undef,
              'isDeprecated' => do{my $o},
              'name' => 'args',
              'type' => {
                'kind' => 'NON_NULL',
                'name' => undef,
                'ofType' => {
                  'kind' => 'LIST',
                  'name' => undef,
                  'ofType' => {
                    'kind' => 'NON_NULL',
                    'name' => undef,
                    'ofType' => {
                      'kind' => 'OBJECT',
                      'name' => '__InputValue',
                      'ofType' => undef
                    }
                  }
                }
              }
            },
            {
              'args' => [],
              'deprecationReason' => undef,
              'description' => undef,
              'isDeprecated' => do{my $o},
              'name' => 'description',
              'type' => {
                'kind' => 'SCALAR',
                'name' => 'String',
                'ofType' => undef
              }
            },
            {
              'args' => [],
              'deprecationReason' => undef,
              'description' => undef,
              'isDeprecated' => do{my $o},
              'name' => 'locations',
              'type' => {
                'kind' => 'NON_NULL',
                'name' => undef,
                'ofType' => {
                  'kind' => 'LIST',
                  'name' => undef,
                  'ofType' => {
                    'kind' => 'NON_NULL',
                    'name' => undef,
                    'ofType' => {
                      'kind' => 'ENUM',
                      'name' => '__DirectiveLocation',
                      'ofType' => undef
                    }
                  }
                }
              }
            },
            {
              'args' => [],
              'deprecationReason' => undef,
              'description' => undef,
              'isDeprecated' => do{my $o},
              'name' => 'name',
              'type' => {
                'kind' => 'NON_NULL',
                'name' => undef,
                'ofType' => {
                  'kind' => 'SCALAR',
                  'name' => 'String',
                  'ofType' => undef
                }
              }
            }
          ],
          'inputFields' => undef,
          'interfaces' => [],
          'kind' => 'OBJECT',
          'name' => '__Directive',
          'possibleTypes' => undef
        },
        {
          'description' => 'A Directive can be adjacent to many parts of the GraphQL language, a __DirectiveLocation describes one such possible adjacencies.',
          'enumValues' => [
            {
              'deprecationReason' => undef,
              'description' => 'Location adjacent to an argument definition.',
              'isDeprecated' => do{my $o},
              'name' => 'ARGUMENT_DEFINITION'
            },
            {
              'deprecationReason' => undef,
              'description' => 'Location adjacent to an enum definition.',
              'isDeprecated' => do{my $o},
              'name' => 'ENUM'
            },
            {
              'deprecationReason' => undef,
              'description' => 'Location adjacent to an enum value definition.',
              'isDeprecated' => do{my $o},
              'name' => 'ENUM_VALUE'
            },
            {
              'deprecationReason' => undef,
              'description' => 'Location adjacent to a field.',
              'isDeprecated' => do{my $o},
              'name' => 'FIELD'
            },
            {
              'deprecationReason' => undef,
              'description' => 'Location adjacent to a field definition.',
              'isDeprecated' => do{my $o},
              'name' => 'FIELD_DEFINITION'
            },
            {
              'deprecationReason' => undef,
              'description' => 'Location adjacent to a fragment definition.',
              'isDeprecated' => do{my $o},
              'name' => 'FRAGMENT_DEFINITION'
            },
            {
              'deprecationReason' => undef,
              'description' => 'Location adjacent to a fragment spread.',
              'isDeprecated' => do{my $o},
              'name' => 'FRAGMENT_SPREAD'
            },
            {
              'deprecationReason' => undef,
              'description' => 'Location adjacent to an inline fragment.',
              'isDeprecated' => do{my $o},
              'name' => 'INLINE_FRAGMENT'
            },
            {
              'deprecationReason' => undef,
              'description' => 'Location adjacent to an input object field definition.',
              'isDeprecated' => do{my $o},
              'name' => 'INPUT_FIELD_DEFINITION'
            },
            {
              'deprecationReason' => undef,
              'description' => 'Location adjacent to an input object type definition.',
              'isDeprecated' => do{my $o},
              'name' => 'INPUT_OBJECT'
            },
            {
              'deprecationReason' => undef,
              'description' => 'Location adjacent to an interface definition.',
              'isDeprecated' => do{my $o},
              'name' => 'INTERFACE'
            },
            {
              'deprecationReason' => undef,
              'description' => 'Location adjacent to a mutation operation.',
              'isDeprecated' => do{my $o},
              'name' => 'MUTATION'
            },
            {
              'deprecationReason' => undef,
              'description' => 'Location adjacent to an object type definition.',
              'isDeprecated' => do{my $o},
              'name' => 'OBJECT'
            },
            {
              'deprecationReason' => undef,
              'description' => 'Location adjacent to a query operation.',
              'isDeprecated' => do{my $o},
              'name' => 'QUERY'
            },
            {
              'deprecationReason' => undef,
              'description' => 'Location adjacent to a scalar definition.',
              'isDeprecated' => do{my $o},
              'name' => 'SCALAR'
            },
            {
              'deprecationReason' => undef,
              'description' => 'Location adjacent to a schema definition.',
              'isDeprecated' => do{my $o},
              'name' => 'SCHEMA'
            },
            {
              'deprecationReason' => undef,
              'description' => 'Location adjacent to a subscription operation.',
              'isDeprecated' => do{my $o},
              'name' => 'SUBSCRIPTION'
            },
            {
              'deprecationReason' => undef,
              'description' => 'Location adjacent to a union definition.',
              'isDeprecated' => do{my $o},
              'name' => 'UNION'
            }
          ],
          'fields' => undef,
          'inputFields' => undef,
          'interfaces' => undef,
          'kind' => 'ENUM',
          'name' => '__DirectiveLocation',
          'possibleTypes' => undef
        },
        {
          'description' => 'One possible value for a given Enum. Enum values are unique values, not a placeholder for a string or numeric value. However an Enum value is returned in a JSON response as a string.',
          'enumValues' => undef,
          'fields' => [
            {
              'args' => [],
              'deprecationReason' => undef,
              'description' => undef,
              'isDeprecated' => do{my $o},
              'name' => 'deprecationReason',
              'type' => {
                'kind' => 'SCALAR',
                'name' => 'String',
                'ofType' => undef
              }
            },
            {
              'args' => [],
              'deprecationReason' => undef,
              'description' => undef,
              'isDeprecated' => do{my $o},
              'name' => 'description',
              'type' => {
                'kind' => 'SCALAR',
                'name' => 'String',
                'ofType' => undef
              }
            },
            {
              'args' => [],
              'deprecationReason' => undef,
              'description' => undef,
              'isDeprecated' => do{my $o},
              'name' => 'isDeprecated',
              'type' => {
                'kind' => 'NON_NULL',
                'name' => undef,
                'ofType' => {
                  'kind' => 'SCALAR',
                  'name' => 'Boolean',
                  'ofType' => undef
                }
              }
            },
            {
              'args' => [],
              'deprecationReason' => undef,
              'description' => undef,
              'isDeprecated' => do{my $o},
              'name' => 'name',
              'type' => {
                'kind' => 'NON_NULL',
                'name' => undef,
                'ofType' => {
                  'kind' => 'SCALAR',
                  'name' => 'String',
                  'ofType' => undef
                }
              }
            }
          ],
          'inputFields' => undef,
          'interfaces' => [],
          'kind' => 'OBJECT',
          'name' => '__EnumValue',
          'possibleTypes' => undef
        },
        {
          'description' => 'Object and Interface types are described by a list of Fields, each of which has a name, potentially a list of arguments, and a return type.',
          'enumValues' => undef,
          'fields' => [
            {
              'args' => [],
              'deprecationReason' => undef,
              'description' => undef,
              'isDeprecated' => do{my $o},
              'name' => 'args',
              'type' => {
                'kind' => 'NON_NULL',
                'name' => undef,
                'ofType' => {
                  'kind' => 'LIST',
                  'name' => undef,
                  'ofType' => {
                    'kind' => 'NON_NULL',
                    'name' => undef,
                    'ofType' => {
                      'kind' => 'OBJECT',
                      'name' => '__InputValue',
                      'ofType' => undef
                    }
                  }
                }
              }
            },
            {
              'args' => [],
              'deprecationReason' => undef,
              'description' => undef,
              'isDeprecated' => do{my $o},
              'name' => 'deprecationReason',
              'type' => {
                'kind' => 'SCALAR',
                'name' => 'String',
                'ofType' => undef
              }
            },
            {
              'args' => [],
              'deprecationReason' => undef,
              'description' => undef,
              'isDeprecated' => do{my $o},
              'name' => 'description',
              'type' => {
                'kind' => 'SCALAR',
                'name' => 'String',
                'ofType' => undef
              }
            },
            {
              'args' => [],
              'deprecationReason' => undef,
              'description' => undef,
              'isDeprecated' => do{my $o},
              'name' => 'isDeprecated',
              'type' => {
                'kind' => 'NON_NULL',
                'name' => undef,
                'ofType' => {
                  'kind' => 'SCALAR',
                  'name' => 'Boolean',
                  'ofType' => undef
                }
              }
            },
            {
              'args' => [],
              'deprecationReason' => undef,
              'description' => undef,
              'isDeprecated' => do{my $o},
              'name' => 'name',
              'type' => {
                'kind' => 'NON_NULL',
                'name' => undef,
                'ofType' => {
                  'kind' => 'SCALAR',
                  'name' => 'String',
                  'ofType' => undef
                }
              }
            },
            {
              'args' => [],
              'deprecationReason' => undef,
              'description' => undef,
              'isDeprecated' => do{my $o},
              'name' => 'type',
              'type' => {
                'kind' => 'NON_NULL',
                'name' => undef,
                'ofType' => {
                  'kind' => 'OBJECT',
                  'name' => '__Type',
                  'ofType' => undef
                }
              }
            }
          ],
          'inputFields' => undef,
          'interfaces' => [],
          'kind' => 'OBJECT',
          'name' => '__Field',
          'possibleTypes' => undef
        },
        {
          'description' => 'Arguments provided to Fields or Directives and the input fields of an InputObject are represented as Input Values which describe their type and optionally a default value.',
          'enumValues' => undef,
          'fields' => [
            {
              'args' => [],
              'deprecationReason' => undef,
              'description' => 'A GraphQL-formatted string representing the default value for this input value.',
              'isDeprecated' => do{my $o},
              'name' => 'defaultValue',
              'type' => {
                'kind' => 'SCALAR',
                'name' => 'String',
                'ofType' => undef
              }
            },
            {
              'args' => [],
              'deprecationReason' => undef,
              'description' => undef,
              'isDeprecated' => do{my $o},
              'name' => 'description',
              'type' => {
                'kind' => 'SCALAR',
                'name' => 'String',
                'ofType' => undef
              }
            },
            {
              'args' => [],
              'deprecationReason' => undef,
              'description' => undef,
              'isDeprecated' => do{my $o},
              'name' => 'name',
              'type' => {
                'kind' => 'NON_NULL',
                'name' => undef,
                'ofType' => {
                  'kind' => 'SCALAR',
                  'name' => 'String',
                  'ofType' => undef
                }
              }
            },
            {
              'args' => [],
              'deprecationReason' => undef,
              'description' => undef,
              'isDeprecated' => do{my $o},
              'name' => 'type',
              'type' => {
                'kind' => 'NON_NULL',
                'name' => undef,
                'ofType' => {
                  'kind' => 'OBJECT',
                  'name' => '__Type',
                  'ofType' => undef
                }
              }
            }
          ],
          'inputFields' => undef,
          'interfaces' => [],
          'kind' => 'OBJECT',
          'name' => '__InputValue',
          'possibleTypes' => undef
        },
        {
          'description' => 'A GraphQL Schema defines the capabilities of a GraphQL server. It exposes all available types and directives on the server, as well as the entry points for query, mutation, and subscription operations.',
          'enumValues' => undef,
          'fields' => [
            {
              'args' => [],
              'deprecationReason' => undef,
              'description' => 'A list of all directives supported by this server.',
              'isDeprecated' => do{my $o},
              'name' => 'directives',
              'type' => {
                'kind' => 'NON_NULL',
                'name' => undef,
                'ofType' => {
                  'kind' => 'LIST',
                  'name' => undef,
                  'ofType' => {
                    'kind' => 'NON_NULL',
                    'name' => undef,
                    'ofType' => {
                      'kind' => 'OBJECT',
                      'name' => '__Directive',
                      'ofType' => undef
                    }
                  }
                }
              }
            },
            {
              'args' => [],
              'deprecationReason' => undef,
              'description' => 'If this server supports mutation, the type that mutation operations will be rooted at.',
              'isDeprecated' => do{my $o},
              'name' => 'mutationType',
              'type' => {
                'kind' => 'OBJECT',
                'name' => '__Type',
                'ofType' => undef
              }
            },
            {
              'args' => [],
              'deprecationReason' => undef,
              'description' => 'The type that query operations will be rooted at.',
              'isDeprecated' => do{my $o},
              'name' => 'queryType',
              'type' => {
                'kind' => 'NON_NULL',
                'name' => undef,
                'ofType' => {
                  'kind' => 'OBJECT',
                  'name' => '__Type',
                  'ofType' => undef
                }
              }
            },
            {
              'args' => [],
              'deprecationReason' => undef,
              'description' => 'If this server support subscription, the type that subscription operations will be rooted at.',
              'isDeprecated' => do{my $o},
              'name' => 'subscriptionType',
              'type' => {
                'kind' => 'OBJECT',
                'name' => '__Type',
                'ofType' => undef
              }
            },
            {
              'args' => [],
              'deprecationReason' => undef,
              'description' => 'A list of all types supported by this server.',
              'isDeprecated' => do{my $o},
              'name' => 'types',
              'type' => {
                'kind' => 'NON_NULL',
                'name' => undef,
                'ofType' => {
                  'kind' => 'LIST',
                  'name' => undef,
                  'ofType' => {
                    'kind' => 'NON_NULL',
                    'name' => undef,
                    'ofType' => {
                      'kind' => 'OBJECT',
                      'name' => '__Type',
                      'ofType' => undef
                    }
                  }
                }
              }
            }
          ],
          'inputFields' => undef,
          'interfaces' => [],
          'kind' => 'OBJECT',
          'name' => '__Schema',
          'possibleTypes' => undef
        },
        {
          'description' => 'The fundamental unit of any GraphQL Schema is the type. There are many kinds of types in GraphQL as represented by the `__TypeKind` enum.

Depending on the kind of a type, certain fields describe information about that type. Scalar types provide no information beyond a name and description, while Enum types provide their values. Object and Interface types provide the fields they describe. Abstract types, Union and Interface, provide the Object types possible at runtime. List and NonNull types compose other types.',
          'enumValues' => undef,
          'fields' => [
            {
              'args' => [],
              'deprecationReason' => undef,
              'description' => undef,
              'isDeprecated' => do{my $o},
              'name' => 'description',
              'type' => {
                'kind' => 'SCALAR',
                'name' => 'String',
                'ofType' => undef
              }
            },
            {
              'args' => [
                {
                  'defaultValue' => 'false',
                  'description' => undef,
                  'name' => 'includeDeprecated',
                  'type' => {
                    'kind' => 'SCALAR',
                    'name' => 'Boolean',
                    'ofType' => undef
                  }
                }
              ],
              'deprecationReason' => undef,
              'description' => undef,
              'isDeprecated' => do{my $o},
              'name' => 'enumValues',
              'type' => {
                'kind' => 'LIST',
                'name' => undef,
                'ofType' => {
                  'kind' => 'NON_NULL',
                  'name' => undef,
                  'ofType' => {
                    'kind' => 'OBJECT',
                    'name' => '__EnumValue',
                    'ofType' => undef
                  }
                }
              }
            },
            {
              'args' => [
                {
                  'defaultValue' => 'false',
                  'description' => undef,
                  'name' => 'includeDeprecated',
                  'type' => {
                    'kind' => 'SCALAR',
                    'name' => 'Boolean',
                    'ofType' => undef
                  }
                }
              ],
              'deprecationReason' => undef,
              'description' => undef,
              'isDeprecated' => do{my $o},
              'name' => 'fields',
              'type' => {
                'kind' => 'LIST',
                'name' => undef,
                'ofType' => {
                  'kind' => 'NON_NULL',
                  'name' => undef,
                  'ofType' => {
                    'kind' => 'OBJECT',
                    'name' => '__Field',
                    'ofType' => undef
                  }
                }
              }
            },
            {
              'args' => [],
              'deprecationReason' => undef,
              'description' => undef,
              'isDeprecated' => do{my $o},
              'name' => 'inputFields',
              'type' => {
                'kind' => 'LIST',
                'name' => undef,
                'ofType' => {
                  'kind' => 'NON_NULL',
                  'name' => undef,
                  'ofType' => {
                    'kind' => 'OBJECT',
                    'name' => '__InputValue',
                    'ofType' => undef
                  }
                }
              }
            },
            {
              'args' => [],
              'deprecationReason' => undef,
              'description' => undef,
              'isDeprecated' => do{my $o},
              'name' => 'interfaces',
              'type' => {
                'kind' => 'LIST',
                'name' => undef,
                'ofType' => {
                  'kind' => 'NON_NULL',
                  'name' => undef,
                  'ofType' => {
                    'kind' => 'OBJECT',
                    'name' => '__Type',
                    'ofType' => undef
                  }
                }
              }
            },
            {
              'args' => [],
              'deprecationReason' => undef,
              'description' => undef,
              'isDeprecated' => do{my $o},
              'name' => 'kind',
              'type' => {
                'kind' => 'NON_NULL',
                'name' => undef,
                'ofType' => {
                  'kind' => 'ENUM',
                  'name' => '__TypeKind',
                  'ofType' => undef
                }
              }
            },
            {
              'args' => [],
              'deprecationReason' => undef,
              'description' => undef,
              'isDeprecated' => do{my $o},
              'name' => 'name',
              'type' => {
                'kind' => 'SCALAR',
                'name' => 'String',
                'ofType' => undef
              }
            },
            {
              'args' => [],
              'deprecationReason' => undef,
              'description' => undef,
              'isDeprecated' => do{my $o},
              'name' => 'ofType',
              'type' => {
                'kind' => 'OBJECT',
                'name' => '__Type',
                'ofType' => undef
              }
            },
            {
              'args' => [],
              'deprecationReason' => undef,
              'description' => undef,
              'isDeprecated' => do{my $o},
              'name' => 'possibleTypes',
              'type' => {
                'kind' => 'LIST',
                'name' => undef,
                'ofType' => {
                  'kind' => 'NON_NULL',
                  'name' => undef,
                  'ofType' => {
                    'kind' => 'OBJECT',
                    'name' => '__Type',
                    'ofType' => undef
                  }
                }
              }
            }
          ],
          'inputFields' => undef,
          'interfaces' => [],
          'kind' => 'OBJECT',
          'name' => '__Type',
          'possibleTypes' => undef
        },
        {
          'description' => 'An enum describing what kind of type a given `__Type` is.',
          'enumValues' => [
            {
              'deprecationReason' => undef,
              'description' => 'Indicates this type is an enum. `enumValues` is a valid field.',
              'isDeprecated' => do{my $o},
              'name' => 'ENUM'
            },
            {
              'deprecationReason' => undef,
              'description' => 'Indicates this type is an input object. `inputFields` is a valid field.',
              'isDeprecated' => do{my $o},
              'name' => 'INPUT_OBJECT'
            },
            {
              'deprecationReason' => undef,
              'description' => 'Indicates this type is an interface. `fields` and `possibleTypes` are valid fields.',
              'isDeprecated' => do{my $o},
              'name' => 'INTERFACE'
            },
            {
              'deprecationReason' => undef,
              'description' => 'Indicates this type is a list. `ofType` is a valid field.',
              'isDeprecated' => do{my $o},
              'name' => 'LIST'
            },
            {
              'deprecationReason' => undef,
              'description' => 'Indicates this type is a non-null. `ofType` is a valid field.',
              'isDeprecated' => do{my $o},
              'name' => 'NON_NULL'
            },
            {
              'deprecationReason' => undef,
              'description' => 'Indicates this type is an object. `fields` and `interfaces` are valid fields.',
              'isDeprecated' => do{my $o},
              'name' => 'OBJECT'
            },
            {
              'deprecationReason' => undef,
              'description' => 'Indicates this type is a scalar.',
              'isDeprecated' => do{my $o},
              'name' => 'SCALAR'
            },
            {
              'deprecationReason' => undef,
              'description' => 'Indicates this type is a union. `possibleTypes` is a valid field.',
              'isDeprecated' => do{my $o},
              'name' => 'UNION'
            }
          ],
          'fields' => undef,
          'inputFields' => undef,
          'interfaces' => undef,
          'kind' => 'ENUM',
          'name' => '__TypeKind',
          'possibleTypes' => undef
        }
      ]
    }
  }
};
$VAR1->{'data'}{'__schema'}{'types'}[3]{'fields'}[0]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[3]{'fields'}[1]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[3]{'fields'}[2]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[3]{'fields'}[3]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[4]{'enumValues'}[0]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[4]{'enumValues'}[1]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[4]{'enumValues'}[2]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[4]{'enumValues'}[3]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[4]{'enumValues'}[4]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[4]{'enumValues'}[5]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[4]{'enumValues'}[6]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[4]{'enumValues'}[7]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[4]{'enumValues'}[8]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[4]{'enumValues'}[9]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[4]{'enumValues'}[10]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[4]{'enumValues'}[11]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[4]{'enumValues'}[12]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[4]{'enumValues'}[13]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[4]{'enumValues'}[14]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[4]{'enumValues'}[15]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[4]{'enumValues'}[16]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[4]{'enumValues'}[17]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[5]{'fields'}[0]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[5]{'fields'}[1]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[5]{'fields'}[2]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[5]{'fields'}[3]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[6]{'fields'}[0]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[6]{'fields'}[1]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[6]{'fields'}[2]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[6]{'fields'}[3]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[6]{'fields'}[4]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[6]{'fields'}[5]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[7]{'fields'}[0]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[7]{'fields'}[1]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[7]{'fields'}[2]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[7]{'fields'}[3]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[8]{'fields'}[0]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[8]{'fields'}[1]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[8]{'fields'}[2]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[8]{'fields'}[3]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[8]{'fields'}[4]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[9]{'fields'}[0]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[9]{'fields'}[1]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[9]{'fields'}[2]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[9]{'fields'}[3]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[9]{'fields'}[4]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[9]{'fields'}[5]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[9]{'fields'}[6]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[9]{'fields'}[7]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[9]{'fields'}[8]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[10]{'enumValues'}[0]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[10]{'enumValues'}[1]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[10]{'enumValues'}[2]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[10]{'enumValues'}[3]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[10]{'enumValues'}[4]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[10]{'enumValues'}[5]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[10]{'enumValues'}[6]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
$VAR1->{'data'}{'__schema'}{'types'}[10]{'enumValues'}[7]{'isDeprecated'} = $VAR1->{'data'}{'__schema'}{'types'}[1]{'fields'}[0]{'isDeprecated'};
