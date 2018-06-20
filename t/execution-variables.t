use lib 't/lib';
use GQLTest;

BEGIN {
  use_ok( 'GraphQL::Type::Scalar', qw($String) ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::InputObject' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Object' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Schema' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Execution', qw(execute) ) || print "Bail out!\n";
}

my $JSON = JSON::MaybeXS->new->allow_nonref->canonical;

my $TestComplexScalar = GraphQL::Type::Scalar->new(
  name => 'ComplexScalar',
  serialize => sub {
    return 'SerializedValue' if $_[0]//'' eq 'DeserializedValue';
    return;
  },
  parse_value => sub {
    return 'DeserializedValue' if $_[0]//'' eq 'SerializedValue';
    return;
  },
);

my $TestInputObject = GraphQL::Type::InputObject->new(
  name => 'TestInputObject',
  fields => {
    a => { type => $String },
    b => { type => $String->list },
    c => { type => $String->non_null },
    d => { type => $TestComplexScalar },
  },
);

my $TestNestedInputObject = GraphQL::Type::InputObject->new(
  name => 'TestNestedInputObject',
  fields => {
    na => { type => $TestInputObject->non_null },
    nb => { type => $String->non_null },
  },
);

my $TestType = GraphQL::Type::Object->new(
  name => 'TestType',
  fields => {
    fieldWithObjectInput => {
      type => $String,
      args => { input => { type => $TestInputObject } },
      resolve => sub { $_[1]->{input} && $JSON->encode($_[1]->{input}) },
    },
    fieldWithNullableStringInput => {
      type => $String,
      args => { input => { type => $String } },
      resolve => sub { $_[1]->{input} && $JSON->encode($_[1]->{input}) },
    },
    fieldWithNonNullableStringInput => {
      type => $String,
      args => { input => { type => $String->non_null } },
      resolve => sub { $_[1]->{input} && $JSON->encode($_[1]->{input}) },
    },
    fieldWithDefaultArgumentValue => {
      type => $String,
      args => { input => { type => $String->non_null, default_value => 'Hello World' } },
      resolve => sub { $_[1]->{input} && $JSON->encode($_[1]->{input}) },
    },
    # is correct as brings in type to schema. zap default_value as fails type
    fieldWithNestedInputObject => {
      type => $String,
      args => { input => { type => $TestNestedInputObject } },
      resolve => sub { $_[1]->{input} && $JSON->encode($_[1]->{input}) },
    },
    list => {
      type => $String,
      args => { input => { type => $String->list } },
      resolve => sub { $_[1]->{input} && $JSON->encode($_[1]->{input}) },
    },
    nnList => {
      type => $String,
      args => { input => { type => $String->list->non_null } },
      resolve => sub { $_[1]->{input} && $JSON->encode($_[1]->{input}) },
    },
    listNN => {
      type => $String,
      args => { input => { type => $String->non_null->list } },
      resolve => sub { $_[1]->{input} && $JSON->encode($_[1]->{input}) },
    },
    nnListNN => {
      type => $String,
      args => { input => { type => $String->non_null->list->non_null } },
      resolve => sub { $_[1]->{input} && $JSON->encode($_[1]->{input}) },
    },
  },
);

my $schema = GraphQL::Schema->new(query => $TestType);

subtest 'Handles objects and nullability', sub {
  subtest 'using inline structs', sub {
    subtest 'executes with complex input', sub {
      my $doc = '{
        fieldWithObjectInput(input: {a: "foo", b: ["bar"], c: "baz"})
      }';
      run_test(
        [$schema, $doc],
        { data => { fieldWithObjectInput => '{"a":"foo","b":["bar"],"c":"baz"}' } },
      );
    };

    subtest 'properly parses single value to list', sub {
      my $doc = '{
        fieldWithObjectInput(input: {a: "foo", b: "bar", c: "baz"})
      }';
      run_test(
        [$schema, $doc],
        { data => { fieldWithObjectInput => '{"a":"foo","b":["bar"],"c":"baz"}' } },
      );
    };

    subtest 'properly parses null value to null', sub {
      my $doc = '{
        fieldWithObjectInput(input: {a: null, b: null, c: "C", d: null})
      }';
      run_test(
        [$schema, $doc],
        { data => { fieldWithObjectInput => '{"a":null,"b":null,"c":"C","d":null}' } },
      );
    };

    subtest 'properly parses null value in list', sub {
      my $doc = '{
        fieldWithObjectInput(input: {b: ["A",null,"C"], c: "C"})
      }';
      run_test(
        [$schema, $doc],
        { data => { fieldWithObjectInput => '{"b":["A",null,"C"],"c":"C"}' } },
      );
    };

    subtest 'does not use incorrect value', sub {
      my $doc = '{
        fieldWithObjectInput(input: ["foo", "bar", "baz"])
      }';
      run_test(
        [$schema, $doc],
        {
          data => { fieldWithObjectInput => undef },
          errors => [ { message =>
            qq{Argument 'input' got invalid value ["foo","bar","baz"].\nExpected 'TestInputObject'.\nIn method graphql_to_perl: parameter 1 (\$item): found not an object.\n},
            locations => [ { line => 3, column => 7 } ],
            path => [ 'fieldWithObjectInput' ],
          } ],
        },
      );
    };

    subtest 'properly runs parseLiteral on complex scalar types', sub {
      my $doc = '{
        fieldWithObjectInput(input: {c: "foo", d: "SerializedValue"})
      }';
      run_test(
        [$schema, $doc],
        { data => {
          fieldWithObjectInput => '{"c":"foo","d":"DeserializedValue"}'
        } },
      );
    };
    done_testing;
  };

  subtest 'using variables', sub {
    my $doc = '
      query q($input: TestInputObject) {
        fieldWithObjectInput(input: $input)
      }
    ';
    subtest 'executes with complex input', sub {
      my $vars = { input => { a => 'foo', b => [ 'bar' ], c => 'baz' } };
      run_test(
        [$schema, $doc, undef, undef, $vars],
        { data => { fieldWithObjectInput => '{"a":"foo","b":["bar"],"c":"baz"}' } },
      );
    };

    subtest 'uses default value when not provided', sub {
      my $doc_with_default = '
        query q($input: TestInputObject = {a: "foo", b: ["bar"], c: "baz"}) {
          fieldWithObjectInput(input: $input)
        }
      ';
      run_test(
        [$schema, $doc_with_default],
        { data => { fieldWithObjectInput => '{"a":"foo","b":["bar"],"c":"baz"}' } },
      );
    };

    subtest 'properly parses single value to list', sub {
      my $vars = { input => { a => 'foo', b => 'bar', c => 'baz' } };
      run_test(
        [$schema, $doc, undef, undef, $vars],
        { data => { fieldWithObjectInput => '{"a":"foo","b":["bar"],"c":"baz"}' } },
      );
    };

    subtest 'executes with complex scalar input', sub {
      my $vars = { input => { c => 'foo', d => 'SerializedValue' } };
      run_test(
        [$schema, $doc, undef, undef, $vars],
        { data => {
          fieldWithObjectInput => '{"c":"foo","d":"DeserializedValue"}'
        } },
      );
    };

    subtest 'errors on null for nested non-null', sub {
      my $vars = { input => { a => 'foo', b => 'bar', c => undef } };
      run_test(
        [$schema, $doc, undef, undef, $vars],
        { errors => [ { message =>
          q{Variable '$input' got invalid value {"a":"foo","b":"bar","c":null}.}
          ."\n".q{In field "c": String! given null value.}."\n"
        } ] },
      );
    };

    subtest 'errors on incorrect type', sub {
      my $vars = { input => 'foo bar' };
      run_test(
        [$schema, $doc, undef, undef, $vars],
        { errors => [ { message =>
q{Variable '$input' got invalid value "foo bar".
In method graphql_to_perl: parameter 1 ($item): found not an object.
}
        } ] },
      );
    };

    subtest 'errors on omission of nested non-null', sub {
      my $vars = { input => { a => 'foo', b => 'bar' } };
      run_test(
        [$schema, $doc, undef, undef, $vars],
        { errors => [ { message =>
          q{Variable '$input' got invalid value {"a":"foo","b":"bar"}.}
          ."\n".q{In field "c": String! given null value.}."\n"
        } ] },
      );
    };

    subtest 'errors on deep nested errors and with many errors', sub {
      my $nested_doc = '
        query q($input: TestNestedInputObject) {
          fieldWithNestedObjectInput(input: $input)
        }
      ';
      my $vars = { input => { na => { a => 'foo' } } };
      run_test(
        [$schema, $nested_doc, undef, undef, $vars],
        { errors => [ { message =>
          q{Variable '$input' got invalid value {"na":{"a":"foo"}}.}."\n"
          .q{In field "na": In field "c": String! given null value.}."\n"
          .q{In field "nb": String! given null value.}."\n"
        } ] },
      );
    };

    subtest 'errors on addition of unknown input field', sub {
      my $vars = { input => { b => 'bar', c => 'baz', extra => 'dog' } };
      run_test(
        [$schema, $doc, undef, undef, $vars],
        { errors => [ { message =>
          q{Variable '$input' got invalid value {"b":"bar","c":"baz","extra":"dog"}.}
          ."\n".q{In field "extra": Unknown field.}."\n"
        } ] },
      );
    };
    done_testing;
  };

  subtest 'Handles nullable scalars', sub {
    subtest 'allows nullable inputs to be omitted', sub {
      my $doc = '
        { fieldWithNullableStringInput }
      ';
      run_test(
        [$schema, $doc],
        { data => { fieldWithNullableStringInput => undef } },
      );
    };

    subtest 'allows nullable inputs to be omitted in a variable', sub {
      my $doc = '
        query SetsNullable($value: String) {
          fieldWithNullableStringInput(input: $value)
        }
      ';
      run_test(
        [$schema, $doc],
        { data => { fieldWithNullableStringInput => undef } },
      );
    };

    subtest 'allows nullable inputs to be omitted in an unlisted variable', sub {
      my $doc = '
        query SetsNullable {
          fieldWithNullableStringInput(input: $value)
        }
      ';
      run_test(
        [$schema, $doc],
        { data => { fieldWithNullableStringInput => undef } },
      );
    };

    subtest 'allows nullable inputs to be set to null in a variable', sub {
      my $doc = '
        query SetsNullable($value: String) {
          fieldWithNullableStringInput(input: $value)
        }
      ';
      my $vars = { value => undef };
      run_test(
        [$schema, $doc, undef, undef, $vars],
        { data => { fieldWithNullableStringInput => undef } },
      );
    };

    subtest 'allows nullable inputs to be set to a value in a variable', sub {
      my $doc = '
        query SetsNullable($value: String) {
          fieldWithNullableStringInput(input: $value)
        }
      ';
      my $vars = { value => 'a' };
      run_test(
        [$schema, $doc, undef, undef, $vars],
        { data => { fieldWithNullableStringInput => '"a"' } },
      );
    };

    subtest 'allows nullable inputs to be set to a value directly', sub {
      my $doc = '
        {
          fieldWithNullableStringInput(input: "a")
        }
      ';
      run_test(
        [$schema, $doc],
        { data => { fieldWithNullableStringInput => '"a"' } },
      );
    };
  };

  subtest 'Handles non-nullable scalars', sub {
    subtest 'allows non-nullable inputs to be omitted given a default', sub {
      my $doc = '
        query SetsNonNullable($value: String = "default") {
          fieldWithNonNullableStringInput(input: $value)
        }
      ';
      run_test(
        [$schema, $doc],
        { data => { fieldWithNonNullableStringInput => '"default"' } },
      );
    };

    subtest 'does not allow non-nullable inputs to be omitted in a variable', sub {
      my $doc = '
        query SetsNonNullable($value: String!) {
          fieldWithNonNullableStringInput(input: $value)
        }
      ';
      run_test(
        [$schema, $doc],
        { errors => [ { message =>
          q{Variable '$value' got invalid value null.}."\n".
          q{String! given null value.}."\n"
        } ] },
      );
    };

    subtest 'does not allow non-nullable inputs to be set to null in a variable', sub {
      my $doc = '
        query SetsNonNullable($value: String!) {
          fieldWithNonNullableStringInput(input: $value)
        }
      ';
      my $vars = { value => undef };
      run_test(
        [$schema, $doc, undef, undef, $vars],
        { errors => [ { message =>
          q{Variable '$value' got invalid value null.}."\n".
          q{String! given null value.}."\n"
        } ] },
      );
    };

    subtest 'allows non-nullable inputs to be set to a value in a variable', sub {
      my $doc = '
        query SetsNonNullable($value: String!) {
          fieldWithNonNullableStringInput(input: $value)
        }
      ';
      my $vars = { value => 'a' };
      run_test(
        [$schema, $doc, undef, undef, $vars],
        { data => { fieldWithNonNullableStringInput => '"a"' } },
      );
    };

    subtest 'allows non-nullable inputs to be set to a value directly', sub {
      my $doc = '
        { fieldWithNonNullableStringInput(input: "a") }
      ';
      run_test(
        [$schema, $doc],
        { data => { fieldWithNonNullableStringInput => '"a"' } },
      );
    };

    subtest 'reports error for missing non-nullable inputs', sub {
      my $doc = '
        { fieldWithNonNullableStringInput }
      ';
      run_test(
        [$schema, $doc],
        { data => { fieldWithNonNullableStringInput => undef },
          errors => [ { message =>
            q{Argument 'input' of type 'String!' not given.},
            locations => [ { line => 2, column => 43 } ],
            path => [ 'fieldWithNonNullableStringInput' ],
        } ] },
      );
    };

    subtest 'reports error for array passed into string input', sub {
      my $doc = '
        query SetsNonNullable($value: String!) {
          fieldWithNonNullableStringInput(input: $value)
        }
      ';
      my $vars = { value => [ 1, 2, 3 ] };
      run_test(
        [$schema, $doc, undef, undef, $vars],
        { errors => [ { message =>
          q{Variable '$value' got invalid value [1,2,3].}."\n".
          q{Not a String.}."\n"
        } ] },
      );
    };

    subtest 'reports error for non-provided variables for non-nullable inputs', sub {
      my $doc = '
        { fieldWithNonNullableStringInput(input: $foo) }
      ';
      run_test(
        [$schema, $doc],
        { data => { fieldWithNonNullableStringInput => undef },
          errors => [ { message =>
            q{Argument 'input' of type 'String!' was given variable '$foo' but no runtime value.},
            locations => [ { line => 2, column => 56 } ],
            path => [ 'fieldWithNonNullableStringInput' ],
        } ] },
      );
    };
  };

  subtest 'Handles lists and nullability', sub {
    subtest 'allows lists to be null', sub {
      my $doc = '
        query q($input: [String]) {
          list(input: $input)
        }
      ';
      my $vars = { input => undef };
      run_test(
        [$schema, $doc, undef, undef, $vars],
        { data => { list => undef } },
      );
    };

    subtest 'allows lists to contain values', sub {
      my $doc = '
        query q($input: [String]) {
          list(input: $input)
        }
      ';
      my $vars = { input => [ 'A' ] };
      run_test(
        [$schema, $doc, undef, undef, $vars],
        { data => { list => '["A"]' } },
      );
    };

    subtest 'allows lists to contain null', sub {
      my $doc = '
        query q($input: [String]) {
          list(input: $input)
        }
      ';
      my $vars = { input => [ 'A', undef, 'B' ] };
      run_test(
        [$schema, $doc, undef, undef, $vars],
        { data => { list => '["A",null,"B"]' } },
      );
    };

    subtest 'does not allow non-null lists to be null', sub {
      my $doc = '
        query q($input: [String]!) {
          nnList(input: $input)
        }
      ';
      my $vars = { input => undef };
      run_test(
        [$schema, $doc, undef, undef, $vars],
        { errors => [ { message =>
          q{Variable '$input' got invalid value null.}."\n".
          q{[String]! given null value.}."\n"
        } ] },
      );
    };

    subtest 'allows non-null lists to contain values', sub {
      my $doc = '
        query q($input: [String]!) {
          nnList(input: $input)
        }
      ';
      my $vars = { input => [ 'A' ] };
      run_test(
        [$schema, $doc, undef, undef, $vars],
        { data => { nnList => '["A"]' } },
      );
    };

    subtest 'allows non-null lists to contain null', sub {
      my $doc = '
        query q($input: [String]!) {
          nnList(input: $input)
        }
      ';
      my $vars = { input => [ 'A', undef, 'B' ] };
      run_test(
        [$schema, $doc, undef, undef, $vars],
        { data => { nnList => '["A",null,"B"]' } },
      );
    };

    subtest 'allows lists of non-nulls to be null', sub {
      my $doc = '
        query q($input: [String!]) {
          listNN(input: $input)
        }
      ';
      my $vars = { input => undef };
      run_test(
        [$schema, $doc, undef, undef, $vars],
        { data => { listNN => undef } },
      );
    };

    subtest 'allows lists of non-nulls to contain values', sub {
      my $doc = '
        query q($input: [String!]) {
          listNN(input: $input)
        }
      ';
      my $vars = { input => [ 'A' ] };
      run_test(
        [$schema, $doc, undef, undef, $vars],
        { data => { listNN => '["A"]' } },
      );
    };

    subtest 'does not allow lists of non-nulls to contain null', sub {
      my $doc = '
        query q($input: [String!]) {
          listNN(input: $input)
        }
      ';
      my $vars = { input => [ 'A', undef, 'B' ] };
      run_test(
        [$schema, $doc, undef, undef, $vars],
        { errors => [ { message =>
          q{Variable '$input' got invalid value ["A",null,"B"].}."\n".
          q{In element #1: String! given null value.}."\n"
        } ] },
      );
    };

    subtest 'does not allow non-null lists of non-nulls to be null', sub {
      my $doc = '
        query q($input: [String!]!) {
          nnListNN(input: $input)
        }
      ';
      my $vars = { input => undef };
      run_test(
        [$schema, $doc, undef, undef, $vars],
        { errors => [ { message =>
          q{Variable '$input' got invalid value null.}."\n".
          q{[String!]! given null value.}."\n"
        } ] },
      );
    };

    subtest 'allows non-null lists of non-nulls to contain values', sub {
      my $doc = '
        query q($input: [String!]!) {
          nnListNN(input: $input)
        }
      ';
      my $vars = { input => [ 'A' ] };
      run_test(
        [$schema, $doc, undef, undef, $vars],
        { data => { nnListNN => '["A"]' } },
      );
    };

    subtest 'does not allow non-null lists of non-nulls to contain null', sub {
      my $doc = '
        query q($input: [String!]!) {
          nnListNN(input: $input)
        }
      ';
      my $vars = { input => [ 'A', undef, 'B' ] };
      run_test(
        [$schema, $doc, undef, undef, $vars],
        { errors => [ { message =>
          q{Variable '$input' got invalid value ["A",null,"B"].}."\n".
          q{In element #1: String! given null value.}."\n"
        } ] },
      );
    };

    subtest 'does not allow invalid types to be used as values', sub {
      my $doc = '
        query q($input: TestType!) {
          fieldWithObjectInput(input: $input)
        }
      ';
      my $vars = { input => { list => [ 'A', 'B' ] } };
      run_test(
        [$schema, $doc, undef, undef, $vars],
        { errors => [ { message =>
          q{Variable '$input' is type 'TestType!' which cannot be used as an input type.}."\n"
        } ] },
      );
    };

    subtest 'does not allow unknown types to be used as values', sub {
      my $doc = '
        query q($input: UnknownType!) {
          fieldWithObjectInput(input: $input)
        }
      ';
      my $vars = { input => 'whoknows' };
      run_test(
        [$schema, $doc, undef, undef, $vars],
        { errors => [ { message =>
          q{Unknown type 'UnknownType'.}."\n"
        } ] },
      );
    };
  };

  subtest 'Execute: Uses argument default values', sub {
    subtest 'when no argument provided', sub {
      my $doc = '
        { fieldWithDefaultArgumentValue }
      ';
      run_test(
        [$schema, $doc],
        { data => { fieldWithDefaultArgumentValue => '"Hello World"' } },
      );
    };

    subtest 'when omitted variable provided', sub {
      my $doc = '
        query optionalVariable($optional: String) {
          fieldWithDefaultArgumentValue(input: $optional)
        }
      ';
      run_test(
        [$schema, $doc],
        { data => { fieldWithDefaultArgumentValue => '"Hello World"' } },
      );
    };

    subtest 'not when argument cannot be coerced', sub {
      my $doc = '
        { fieldWithDefaultArgumentValue(input: WRONG_TYPE) }
      ';
      run_test(
        [$schema, $doc],
        { data => { fieldWithDefaultArgumentValue => undef },
          errors => [ { message =>
            q{Argument 'input' of type 'String!' was given WRONG_TYPE which is enum value.},
            locations => [ { line => 2, column => 60 } ],
            path => [ 'fieldWithDefaultArgumentValue' ],
        } ] },
      );
    };
  };
  done_testing;
};

done_testing;
