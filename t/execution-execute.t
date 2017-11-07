use 5.014;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Deep;
use JSON::MaybeXS;
use Data::Dumper;

my $JSON = JSON::MaybeXS->new->allow_nonref->canonical;

BEGIN {
  use_ok( 'GraphQL::Schema' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Object' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Scalar', qw($String $Int $Boolean) ) || print "Bail out!\n";
  use_ok( 'GraphQL::Execution', qw(execute) ) || print "Bail out!\n";
  use_ok( 'GraphQL::Language::Parser', qw(parse) ) || print "Bail out!\n";
}

sub run_test {
  my ($args, $expected) = @_;
  my $got = execute(@$args);
  is_deeply $got, $expected or diag nice_dump($got);
}

sub nice_dump {
  my ($got) = @_;
  local ($Data::Dumper::Sortkeys, $Data::Dumper::Indent, $Data::Dumper::Terse);
  $Data::Dumper::Sortkeys = $Data::Dumper::Indent = $Data::Dumper::Terse = 1;
  Dumper $got;
}

subtest 'throws if no document is provided' => sub {
  my $schema = GraphQL::Schema->new(
    query => GraphQL::Type::Object->new(
      name => 'Type',
      fields => {
        a => { type => $String },
      }
    )
  );
  throws_ok { execute($schema, undef) } qr/Undef did not pass type constraint/;
};

subtest 'executes arbitrary code' => sub {
  my $deep_data;
  my $data = {
    a => sub { 'Apple' },
    b => sub { 'Banana' },
    c => sub { 'Cookie' },
    d => sub { 'Donut' },
    e => sub { 'Egg' },
    f => 'Fish',
    pic => sub {
      my $size = shift;
      return 'Pic of size: ' . ($size || 50);
    },
    deep => sub { $deep_data },
  };

  $deep_data = {
    a => sub { 'Already Been Done' },
    b => sub { 'Boring' },
    c => sub { ['Contrived', undef, 'Confusing'] },
    deeper => sub { [$data, undef, $data] }
  };

  my $DeepDataType;
  my $DataType = GraphQL::Type::Object->new(
    name => 'DataType',
    fields => sub { {
      a => { type => $String },
      b => { type => $String },
      c => { type => $String },
      d => { type => $String },
      e => { type => $String },
      f => { type => $String },
      pic => {
        args => { size => { type => $Int } },
        type => $String,
        resolve => sub {
          my ($obj, $args) = @_;
          return $obj->{pic}->($args->{size});
        }
      },
      deep => { type => $DeepDataType },
    } }
  );

  $DeepDataType = GraphQL::Type::Object->new(
    name => 'DeepDataType',
    fields => {
      a => { type => $String },
      b => { type => $String },
      c => { type => $String->list },
      deeper => { type => $DataType->list },
    }
  );

  my $schema = GraphQL::Schema->new(
    query => $DataType
  );

  my $doc = <<'EOF';
query Example($size: Int) {
  a,
  b,
  x: c
  ...c
  f
  ...on DataType {
    pic(size: $size)
  }
  deep {
    a
    b
    c
    deeper {
      a
      b
    }
  }
}
fragment c on DataType {
  d
  e
}
EOF
  my $ast = parse($doc);

  run_test([$schema, $ast, $data, undef, { size => 100 }, 'Example'], {
    data => {
      a => 'Apple',
      b => 'Banana',
      x => 'Cookie',
      d => 'Donut',
      e => 'Egg',
      f => 'Fish',
      pic => 'Pic of size: 100',
      deep => {
        a => 'Already Been Done',
        b => 'Boring',
        c => ['Contrived', undef, 'Confusing'],
        deeper => [
          { a => 'Apple', b => 'Banana' },
          undef,
          { a => 'Apple', b => 'Banana' },
        ],
      },
    },
  });
};

subtest 'merges parallel fragments' => sub{
  my $ast = parse('
{ a, ...FragOne, ...FragTwo }
fragment FragOne on Type {
  b
  deep { b, deeper: deep { b } }
}
fragment FragTwo on Type {
  c
  deep { c, deeper: deep { c } }
}
  ');

  my $Type;
  $Type = GraphQL::Type::Object->new(
    name => 'Type',
    fields => sub { {
      a => { type => $String, resolve => sub { 'Apple' } },
      b => { type => $String, resolve => sub { 'Banana' } },
      c => { type => $String, resolve => sub { 'Cherry' } },
      deep => { type => $Type, resolve => sub { {} } },
    } },
  );
  my $schema = GraphQL::Schema->new(query => $Type);

  run_test([$schema, $ast], {
    data => {
      a => 'Apple',
      b => 'Banana',
      c => 'Cherry',
      deep => {
        b => 'Banana',
        c => 'Cherry',
        deeper => {
          b => 'Banana',
          c => 'Cherry'
        }
      }
    }
  });
};

subtest 'provides info about current execution state' => sub {
  my $ast = parse('query ($var: String) { result: test }');
  my $info;
  my $schema = GraphQL::Schema->new(
    query => GraphQL::Type::Object->new(
      name => 'Test',
      fields => {
        test => {
          type => $String,
          resolve => sub {
            my ($val, $args, $ctx, $_info) = @_;
            $info = $_info;
          },
        },
      },
    )
  );
  my $rootValue = { root => 'val' };

  execute($schema, $ast, $rootValue, undef, { var => 123 });

  is_deeply [sort keys %$info], [qw/
    field_name
    field_nodes
    fragments
    operation
    parent_type
    path
    return_type
    root_value
    schema
    variable_values
  /];
  is $info->{field_name}, 'test';
  is scalar(@{ $info->{field_nodes} }), 1;
  is_deeply $info->{field_nodes}[0], $ast->[0]{selections}[0];
  is $info->{return_type}->name, $String->name;
  is $info->{parent_type}, $schema->query;
  is_deeply $info->{path}, [ 'result' ];
  is $info->{schema}, $schema;
  is $info->{root_value}, $rootValue;
  is $info->{operation}, $ast->[0];
  is_deeply $info->{variable_values}, { var => {type => $String, value => '123'} };
};

subtest 'threads root value context correctly' => sub {
  my $doc = 'query Example { a }';
  my $data = {
    context_thing => 'thing',
  };

  my $resolved_root_value;

  my $schema = GraphQL::Schema->new(
    query => GraphQL::Type::Object->new(
      name => 'Type',
      fields => {
        a => {
          type => $String,
          resolve => sub {
            my ($root_value) = @_;
            $resolved_root_value = $root_value;
          },
        },
      },
    )
  );

  execute($schema, parse($doc), $data);
  is $resolved_root_value->{context_thing}, 'thing';
};

subtest 'correctly threads arguments' => sub {
  my $doc = <<'EOF';
query Example {
  b(num_arg: 123, string_arg: "foo")
}
EOF

  my $resolved_args;
  my $schema = GraphQL::Schema->new(
    query => GraphQL::Type::Object->new(
      name => 'Type',
      fields => {
        b => {
          args => {
            num_arg => { type => $Int },
            string_arg => { type => $String }
          },
          type => $String,
          resolve => sub {
            my (undef, $args) = @_;
            $resolved_args = $args;
          }
        }
      }
    )
  );

  execute($schema, parse($doc));

  is $resolved_args->{num_arg}, 123;
  is $resolved_args->{string_arg}, 'foo';
};

subtest 'nulls out error subtrees' => sub {
  my $doc = '{
    sync
    syncError
    syncRawError
    syncReturnError
    syncReturnErrorList
  }';
  my $data = {
    sync => sub { 'sync' },
    syncError => sub { die "Error getting syncError\n" },
    syncRawError => sub { die "Error getting syncRawError\n" },
    syncReturnError => sub { GraphQL::Error->coerce('Error getting syncReturnError') },
    syncReturnErrorList => sub {
      [
        'sync0',
        GraphQL::Error->coerce('Error getting syncReturnErrorList1'),
        'sync2',
        GraphQL::Error->coerce('Error getting syncReturnErrorList3')
      ];
    },
  };
  my $ast = parse($doc);
  my $schema = GraphQL::Schema->new(
    query => GraphQL::Type::Object->new(
      name => 'Type',
      fields => {
        sync => { type => $String },
        syncError => { type => $String },
        syncRawError => { type => $String },
        syncReturnError => { type => $String },
        syncReturnErrorList => { type => $String->list },
      }
    )
  );
  my $got = execute($schema, $ast, $data);
  is_deeply $got->{data}, {
    sync => 'sync',
    syncError => undef,
    syncRawError => undef,
    syncReturnError => undef,
    syncReturnErrorList => ['sync0', undef, 'sync2', undef],
  } or diag nice_dump($got->{data});
  is_deeply [ sort { $a->{message} cmp $b->{message} } @{ $got->{errors} } ], [
    {
      message   => "Error getting syncError\n",
      locations => [{ line => 4, column => 5 }],
      path    => ['syncError']
    },
    {
      message   => "Error getting syncRawError\n",
      locations => [{ line => 5, column => 5 }],
      path    => ['syncRawError']
    },
    {
      message   => "Error getting syncReturnError",
      locations => [{ line => 6, column => 5 }],
      path    => ['syncReturnError']
    },
    {
      message   => "Error getting syncReturnErrorList1",
      locations => [{ line => 7, column => 3 }],
      path    => ['syncReturnErrorList', 1]
    },
    {
      message   => "Error getting syncReturnErrorList3",
      locations => [{ line => 7, column => 3 }],
      path    => ['syncReturnErrorList', 3]
    },
  ] or diag nice_dump($got->{errors});
};

subtest 'Full response path is included for non-nullable fields' => sub {
  my $A; $A = GraphQL::Type::Object->new(
    name => 'A',
    fields => sub { {
      nullableA => {
        type => $A,
        resolve => sub { {} },
      },
      nonNullA => {
        type  => $A->non_null,
        resolve => sub { {} },
      },
      throws => {
        type  => $String->non_null,
        resolve => sub { die GraphQL::Error->coerce('Catch me if you can') },
      },
    } },
  );
  my $queryType = GraphQL::Type::Object->new(
    name => 'query',
    fields => sub { {
      nullableA => {
        type  => $A,
        resolve => sub { {} },
      }
    } },
  );
  my $schema = GraphQL::Schema->new(
    query => $queryType,
  );
  my $query = <<EOF;
query {
  nullableA {
    aliasedA: nullableA {
      nonNullA {
        anotherA: nonNullA {
          throws
        }
      }
    }
  }
}
EOF
  my $result = execute($schema, parse($query));
  is_deeply $result, {
    data => {
      nullableA => {
        aliasedA => { nonNullA => { anotherA => {} } },
      },
    },
    errors => [{
      message => 'Catch me if you can',
      locations => [{ line => 7, column => 9 }],
      path => ['nullableA', 'aliasedA', 'nonNullA', 'anotherA', 'throws'],
    }],
  } or diag nice_dump $result;
};

subtest 'uses the inline operation if no operation name is provided' => sub {
  my $doc = '{ a }';
  my $data = { a => 'b' };
  my $ast = parse($doc);
  my $schema = GraphQL::Schema->new(
    query => GraphQL::Type::Object->new(
      name   => 'Type',
      fields => {
        a => { type => $String },
      }
    )
  );

  my $result = execute($schema, $ast, $data);
  is_deeply $result, { data => { a => 'b' } };
};

subtest 'uses the only operation if no operation name is provided' => sub {
  my $doc = 'query Example { a }';
  my $data = { a => 'b' };
  my $ast = parse($doc);
  my $schema = GraphQL::Schema->new(
    query => GraphQL::Type::Object->new(
      name => 'Type',
      fields => {
        a => { type => $String },
      }
    )
  );

  my $result = execute($schema, $ast, $data);

  is_deeply $result, { data => { a => 'b' } };
};

subtest 'uses the named operation if operation name is provided' => sub {
  my $doc = 'query Example { first: a } query OtherExample { second: a }';
  my $data = { a => 'b' };
  my $ast = parse($doc);
  my $schema = GraphQL::Schema->new(
    query => GraphQL::Type::Object->new(
      name => 'Type',
      fields => {
        a => { type => $String },
      }
    )
  );

  my $result = execute($schema, $ast, $data, undef, undef, 'OtherExample');

  is_deeply $result, { data => { second => 'b' } };
};

subtest 'throws if no operation is provided' => sub {
  my $doc = 'fragment Example on Type { a }';
  my $data = { a => 'b' };
  my $ast = parse($doc);
  my $schema = GraphQL::Schema->new(
    query => GraphQL::Type::Object->new(
      name => 'Type',
      fields => {
        a => { type => $String },
      }
    )
  );
  run_test([$schema, $ast, $data], {
    errors => [ {
      message => "No operations supplied.\n",
    } ],
  });
};

subtest 'throws if no operation name is provided with multiple operations' => sub {
  my $doc = 'query Example { a } query OtherExample { a }';
  my $data = { a => 'b' };
  my $ast = parse($doc);
  my $schema = GraphQL::Schema->new(
    query => GraphQL::Type::Object->new(
    name => 'Type',
    fields => {
      a => { type => $String },
    }
    )
  );
  run_test([$schema, $ast, $data], {
    errors => [ {
      message => "Must provide operation name if query contains multiple operations.\n",
    } ],
  });
};

subtest 'throws if unknown operation name is provided' => sub {
  my $doc = 'query Example { a } query OtherExample { a }';
  my $data = { a => 'b' };
  my $ast = parse($doc);
  my $schema = GraphQL::Schema->new(
    query => GraphQL::Type::Object->new(
      name => 'Type',
      fields => {
        a => { type => $String },
      }
    )
  );
  run_test([$schema, $ast, $data, undef, undef, 'UnknownExample'], {
    errors => [ {
      message => qq{No operations matching 'UnknownExample' found.\n},
    } ],
  });
};

subtest 'uses the query schema for queries' => sub {
  my $doc = 'query Q { a } mutation M { c } subscription S { a }';
  my $data = { a => 'b', c => 'd' };
  my $ast = parse($doc);
  my $schema = GraphQL::Schema->new(
    query => GraphQL::Type::Object->new(
      name => 'Q',
      fields => {
        a => { type => $String },
      }
    ),
    mutation => GraphQL::Type::Object->new(
      name => 'M',
      fields => {
        c => { type => $String },
      }
    ),
    subscription => GraphQL::Type::Object->new(
      name => 'S',
      fields => {
        a => { type => $String },
      }
    )
  );

  my $result = execute($schema, $ast, $data, undef, {}, 'Q');
  is_deeply $result, { data => { a => 'b' } };
};

subtest 'uses the mutation schema for mutations' => sub {
  my $doc = 'query Q { a } mutation M { c }';
  my $data = { a => 'b', c => 'd' };
  my $ast = parse($doc);
  my $schema = GraphQL::Schema->new(
    query => GraphQL::Type::Object->new(
      name => 'Q',
      fields => {
        a => { type => $String },
      }
    ),
    mutation => GraphQL::Type::Object->new(
      name => 'M',
      fields => {
        c => { type => $String },
      }
    )
  );

  my $mutationResult = execute($schema, $ast, $data, undef, {}, 'M');
  is_deeply $mutationResult, { data => { c => 'd' } };
};

subtest 'uses the subscription schema for subscriptions' => sub {
  my $doc = 'query Q { a } subscription S { a }';
  my $data = { a => 'b', c => 'd' };
  my $ast = parse($doc);
  my $schema = GraphQL::Schema->new(
    query => GraphQL::Type::Object->new(
      name => 'Q',
      fields => {
        a => { type => $String },
      }
    ),
    subscription => GraphQL::Type::Object->new(
      name => 'S',
      fields => {
        a => { type => $String },
      }
    )
  );

  my $subscription_result = execute($schema, $ast, $data, undef, {}, 'S');
  is_deeply $subscription_result, { data => { a => 'b' } };
};

subtest 'Avoids recursion' => sub {
  my $doc = '
    query Q {
      a
      ...Frag
      ...Frag
    }
    fragment Frag on Type {
      a,
      ...Frag
    }
  ';
  my $data = { a => 'b' };
  my $ast = parse($doc);
  my $schema = GraphQL::Schema->new(
    query => GraphQL::Type::Object->new(
      name => 'Type',
      fields => {
        a => { type => $String },
      }
    ),
  );

  my $queryResult = execute($schema, $ast, $data, undef, {}, 'Q');
  is_deeply $queryResult, { data => { a => 'b' } };
};

subtest 'does not include illegal fields in output' => sub {
  my $doc = 'mutation M {
    thisIsIllegalDontIncludeMe
  }';
  my $ast = parse($doc);
  my $schema = GraphQL::Schema->new(
    query => GraphQL::Type::Object->new(
      name => 'Q',
      fields => {
        a => { type => $String },
      }
    ),
    mutation => GraphQL::Type::Object->new(
      name => 'M',
      fields => {
        c => { type => $String },
      }
    ),
  );

  run_test([$schema, $ast], {
    data => {},
    errors => [ {
      locations => [ { 'column' => 3, 'line' => 3 } ],
      message => 'No field M.thisIsIllegalDontIncludeMe.',
      path => [ 'thisIsIllegalDontIncludeMe' ],
    } ],
  });
};

subtest 'does not include arguments that were not set' => sub {
  my $schema = GraphQL::Schema->new(
    query => GraphQL::Type::Object->new(
      name => 'Type',
      fields => {
        field => {
          type => $String,
          resolve => sub {
            my ($data, $args) = @_;
            return $JSON->encode($args);
          },
          args => {
            a => { type => $Boolean },
            b => { type => $Boolean },
            c => { type => $Boolean },
            d => { type => $Int },
            e => { type => $Int },
          },
        }
      }
    )
  );

  my $query = parse('{ field(a: true, c: false, e: 0) }');
  run_test([$schema, $query], {
    data => { field => '{"a":1,"c":0,"e":0}' }
  });
};

subtest 'fails when an is_type_of check is not met' => sub {
  {
    package Special;
    sub new {
      my ($class, $value) = @_;
      return bless { value => $value }, $class;
    }
    sub value { shift->{value} }

    package NotSpecial;
    sub new {
      my ($class, $value) = @_;
      return bless { value => $value }, $class;
    }
    sub value { shift->{value} }
  }

  my $SpecialType = GraphQL::Type::Object->new(
    name => 'SpecialType',
    is_type_of => sub {
      my $obj = shift;
      return $obj->isa('Special');
    },
    fields => {
      value => { type => $String }
    }
  );

  my $schema = GraphQL::Schema->new(
    query => GraphQL::Type::Object->new(
      name => 'Query',
      fields => {
        specials => {
          type => $SpecialType->list,
          resolve => sub {
            my $root_value = shift;
            return $root_value->{specials};
          }
        }
      }
    )
  );

  my $query = parse('{ specials { value } }');
  my $value = {
    specials => [Special->new('foo'), NotSpecial->new('bar')]
  };
  run_test([$schema, $query, $value], {
    data => {
      specials => [
        { value => 'foo' },
        undef,
      ],
    },
    errors => [
      {
        message => "Expected a value of type 'SpecialType' but received: 'NotSpecial'.",
        locations => [{ line => 1, column => 22 }],
        path => [ 'specials', 1 ],
      }
    ],
  });
};

subtest 'fails to execute a query containing a type definition' => sub {
  my $query = parse('
    { foo }
    type Query { foo: String }
  ');

  my $schema = GraphQL::Schema->new(
    query => GraphQL::Type::Object->new(
      name => 'Query',
      fields => {
        foo => { type => $String }
      }
    )
  );
  run_test([$schema, $query], {
    errors => [ {
      message => "Can only execute document containing fragments or operations\n",
    } ],
  });
};

done_testing;
