package GraphQL::Plugin::Convert::Test;

use Moo;
use GraphQL::Schema;
extends qw(GraphQL::Plugin::Convert);

=head1 NAME

GraphQL::Plugin::Convert::Test - GraphQL plugin test class

=head1 SYNOPSIS

  package main;
  use GraphQL::Plugin::Convert::Test;
  use GraphQL::Execution qw(execute);
  my $converted = GraphQL::Plugin::Convert::Test->to_graphql;
  print execute(
    $converted->{schema}, '{helloWorld}', $converted->{root_value}
  )->{data}{helloWorld}, "\n";

=head1 DESCRIPTION

Example class to allow testing of convert plugin consumers.

=head1 METHODS

Produces a schema and root value that defines the top-level query field
C<helloWorld>. That will return the string C<Hello, world!>.

=head2 to_graphql(@values)

Ignores all inputs.

=cut

sub to_graphql {
  +{
    schema => GraphQL::Schema->from_doc('type Query { helloWorld: String }'),
    root_value => { helloWorld => 'Hello, world!' },
  };
}

__PACKAGE__->meta->make_immutable();

1;
