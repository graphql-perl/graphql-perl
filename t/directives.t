use lib 't/lib';
use GQLTest;

BEGIN {
  use_ok( 'GraphQL::Schema' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Execution', qw(execute) ) || print "Bail out!\n";
}

my $doc = q<
  directive @length(max: Int) on FIELD_DEFINITION | INPUT_FIELD_DEFINITION
  directive @note(msg: Str) on SCHEMA | SCALAR | OBJECT | FIELD_DEFINITION
    | ARGUMENT_DEFINITION | INTERFACE | UNION | ENUM | ENUM_VALUE
    | INPUT_OBJECT | INPUT_FIELD_DEFINITION

  type Todo {
    task: String! @length(max: 15)
  }

  type Query {
    todos: [Todo]
  }

  type Mutation @length(max: 15) {
    add_todo(task: String! @length(max: 15)): Todo
  }

  schema @note(msg: "Test") {
    query: Query
    mutation: Mutation
  }

>;

ok my $schema = GraphQL::Schema->from_doc($doc);

my @orig_data = my @data = (
  {task => 'Exercise!'},
  {task => 'Bulk Milk'},
  {task => 'Walk Dogs'},
);
my $add_task = { task => 'milk1' };
my $bad_task = { task => 'milk1milk1milk1milk1' };

my %root_value = (
  todos => sub {
    return \@data;
  },
  add_todo => sub {
    my ($args, $context, $info) = @_;
    my $task = $args->{task}; # hardcoding arg name for simplicity
    my $length_dir = _get_directive($info, 'task', 'length');
    if ($length_dir) {
      my $max = $length_dir->{arguments}{max};
      die "Length of '$task' > max=$max\n" if length $task > $max;
    }
    my $data = { task => $task };
    push @data, $data;
    return $data;
  }
);

sub _get_directive {
  my ($info, $arg, $name) = @_;
  my $parent_type = $info->{parent_type};
  my $field_def = $parent_type->fields->{$info->{field_name}};
  my $arg_directives = $field_def->{args}{$arg}{directives}; # would autovivify
  my ($directive) = grep $_->{name} eq $name, @$arg_directives;
  $directive;
}

my $q = q<
  mutation m($task: String!) {
    add_todo(task: $task) { task }
  }
  query q {
    todos { task }
  }
>;

subtest 'basic directives' => sub {
  run_test(
    [$schema, $q, \%root_value, undef, undef, 'q'],
    { data => { todos => \@orig_data } },
  );
  run_test(
    [$schema, $q, \%root_value, undef, $add_task, 'm'],
    { data => { add_todo => $add_task } },
  );
  run_test(
    [$schema, $q, \%root_value, undef, $bad_task, 'm'],
    {
      data => { add_todo => undef },
      errors => [
        {
          locations => [ { column => 3, line => 4 } ],
          message => "Length of 'milk1milk1milk1milk1' > max=15\n",
          path => [ 'add_todo' ]
        }
      ]
    },
  );
  run_test(
    [$schema, $q, \%root_value, undef, undef, 'q'],
    { data => { todos => [ @orig_data, $add_task ] } },
  );
};

done_testing;
