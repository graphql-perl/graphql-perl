package GraphQL::Plugin::Convert;

use Moo;
use strict;
use warnings;

=head1 NAME

GraphQL::Plugin::Convert - GraphQL plugin API abstract class

=head1 SYNOPSIS

  package GraphQL::Plugin::Convert::DBIC;
  use Moo;
  extends qw(GraphQL::Plugin::Convert);
  # ...

  package main;
  use Mojolicious::Lite;
  use Schema;
  use GraphQL::Plugin::Convert::DBIC;
  helper db => sub { Schema->connect('dbi:SQLite:test.db') };
  my $converted = GraphQL::Plugin::Convert::DBIC->to_graphql(app->db);
  plugin GraphQL => {
    map { $_ => $converted->{$_} }
      qw(schema resolver root_value)
  };

  # OR, for knowledgeable consumers of GraphQL::Plugin::Convert APIs:
  package main;
  use Mojolicious::Lite;
  use Schema;
  helper db => sub { Schema->connect('dbi:SQLite:test.db') };
  plugin GraphQL => { convert => [ 'DBIC', app->db ] };

=head1 DESCRIPTION

Abstract class for other GraphQL type classes to inherit from and
implement.

=head1 METHODS

=head2 to_graphql(@values)

When called with suitable values (as defined by the implementing class),
will return a hash-ref with these keys:

=over

=item schema

A L<GraphQL::Schema>.

=item resolver

A code-ref suitable for using as a resolver by
L<GraphQL::Execution/execute>. Optional.

=item root_value

A hash-ref suitable for using as a C<$root_value> by
L<GraphQL::Execution/execute>. Optional.

=back

=head2 from_graphql

When called with a hash-ref shaped as above, with at least a C<schema>
key with a L<GraphQL::Schema>, returns some value(s). Optional to
implement.  If the plugin does implement this, allows conversion from
a GraphQL schema to that plugin's domain.

=cut

__PACKAGE__->meta->make_immutable();

1;
