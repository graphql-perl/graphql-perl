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

  # show schema from shell
  perl -Maliased=GraphQL::Plugin::Convert::Test -e 'print Test->to_graphql->{schema}->to_doc'

=head1 DESCRIPTION

Example class to allow testing of convert plugin consumers.

=head1 METHODS

Produces a schema and root value that defines the top-level query field
C<helloWorld>. That will return the string C<Hello, world!>.

Also has a mutation, C<echo>, that takes a String C<s>, and returns it.

=head2 to_graphql(@values)

If the first value is true, it is a C<subscribe_resolver>,
enabling subscriptions in the generated schema.  It will be returned
as the relevant key in the hash-ref, suitable for being passed as the
relevant arg to L<GraphQL::Subscription/subscribe>.  The schema will have
a subscription field C<timedEcho> that takes a String C<s>, and should
return it periodically, in a way determined by the subscription function.

=cut

sub to_graphql {
  my ($class, $subscribe_resolver) = @_;
  my $sdl = <<'EOF';
type Query { helloWorld: String! }
type Mutation { echo(s: String!): String! }
EOF
  $sdl .= "type Subscription { timedEcho(s: String!): String! }\n"
    if $subscribe_resolver;
  +{
    schema => GraphQL::Schema->from_doc($sdl),
    root_value => {
      helloWorld => 'Hello, world!',
      echo => sub { $_[0]->{s} },
    },
    $subscribe_resolver ? (subscribe_resolver => $subscribe_resolver) : (),
  };
}

__PACKAGE__->meta->make_immutable();

1;
