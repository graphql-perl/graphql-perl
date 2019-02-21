package GraphQL::Plugin::Type;

use Moo;
use Function::Parameters;
use Types::Standard -all;

=head1 NAME

GraphQL::Plugin::Type - GraphQL plugins implementing types

=head1 SYNOPSIS

  package GraphQL::Plugin::Type::DateTime;
  use Moo;
  extends qw(GraphQL::Plugin::Type);
  my $iso8601 = DateTime::Format::ISO8601->new;
  GraphQL::Plugin::Type->register(
    GraphQL::Type::Scalar->new(
      name => 'DateTime',
      serialize => sub { return if !defined $_[0]; $_[0].'' },
      parse_value => sub { return if !defined $_[0]; $iso8601->parse_datetime(@_); },
    )
  );
  1;

  package main;
  use GraphQL::Schema;
  use GraphQL::Plugin::Type::DateTime;
  use GraphQL::Execution qw(execute);
  my $schema = GraphQL::Schema->from_doc(<<'EOF');
  type Query { dateTimeNow: DateTime }
  EOF
  post '/graphql' => sub {
    send_as JSON => execute(
      $schema,
      body_parameters->{query},
      { dateTimeNow => sub { DateTime->now } },
      undef,
      body_parameters->{variables},
      body_parameters->{operationName},
      undef,
    );
  };

=head1 DESCRIPTION

Class implementing the scheme by which additional GraphQL type classes
can be implemented.

The author considers this is only worth doing for scalars, and
indeed this scheme is (now) how the non-standard C<DateTime> is
implemented in graphql-perl. If one wants to create other types
(L<GraphQL::Type::Object>, L<GraphQL::Type::InputObject>, etc), then
the L<Schema Definition Language|GraphQL::Schema/from_doc> is already
available. However, any type can be registered with the L</register>
method, and will be automatically available to L<GraphQL::Schema>
objects with no additional code.

=head1 METHODS

=head2 register($graphql_type)

When called with a L<GraphQL::Type> subclass, will register it,
otherwise dies.

=cut

my @registered;
method register((InstanceOf['GraphQL::Type']) $type) {
  push @registered, $type;
}

=head2 registered

Returns a list of registered classes.

=cut

method registered() {
  @registered;
}

__PACKAGE__->meta->make_immutable();

1;
