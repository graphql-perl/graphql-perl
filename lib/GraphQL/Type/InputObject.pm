package GraphQL::Type::InputObject;

use 5.014;
use strict;
use warnings;
use Moo;
use Types::Standard qw(HashRef ArrayRef Map Dict ConsumerOf Optional Any Str);
use GraphQL::Utilities qw(StrNameValid);
extends qw(GraphQL::Type);
with qw(
  GraphQL::Role::Input
  GraphQL::Role::Nullable
  GraphQL::Role::Named
);

our $VERSION = '0.02';

=head1 NAME

GraphQL::Type::InputObject - GraphQL input object type

=head1 SYNOPSIS

  use GraphQL::Type::InputObject;
  my $type = GraphQL::Type::InputObject->new(
    name => 'InputObject',
    fields => { fieldName => { type => 'GraphQLString', resolve => sub { '' } }},
  );

=head1 ATTRIBUTES

Inherits C<name>, C<description> from L<GraphQL::Type>.

=head2 fields

Hash-ref mapping field names to a hash-ref description. Description keys,
all optional:

=over

=item type

Perl value of that  item. If not specified, will be the string name of
the value. Integers are often useful.

=item default_value

Default value for this argument if none supplied. Must be same type as
the C<type>.

=item description

Description.

=back

=cut

has fields => (
  is => 'ro',
  isa => Map[
    StrNameValid,
    Dict[
      type => ConsumerOf['GraphQL::Role::Input'],
      # TODO: change Any to check that is same as supplied "type". Possibly
      # with builder?
      default_value => Optional[Any],
      description => Optional[Str],
    ]
  ],
  required => 1,
);

=head2 interfaces

Optional array-ref of interface type objects implemented.

=cut

has interfaces => (is => 'ro', isa => ArrayRef);

__PACKAGE__->meta->make_immutable();

1;
