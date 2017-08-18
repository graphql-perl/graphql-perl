package GraphQL::Type::Enum;

use 5.014;
use strict;
use warnings;
use Moo;
use Types::Standard qw(Map Dict Optional Any Str);
use GraphQL::Utilities qw(StrNameValid);
extends qw(GraphQL::Type);
with qw(
  GraphQL::Role::Input
  GraphQL::Role::Output
  GraphQL::Role::Leaf
  GraphQL::Role::Nullable
  GraphQL::Role::Named
);

our $VERSION = '0.02';

=head1 NAME

GraphQL::Type::Enum - GraphQL enum type

=head1 SYNOPSIS

  use GraphQL::Type::Enum;
  my %text2value;
  my $type = GraphQL::Type::Enum->new(
    name => 'Enum',
    values => { value1 => {}, value2 => { value => 'yo' } },
  );

=head1 ATTRIBUTES

Inherits C<name>, C<description> from L<GraphQL::Type>.

=head2 values

Hash-ref mapping value labels to a hash-ref description. Description keys,
all optional:

=over

=item value

Perl value of that  item. If not specified, will be the string name of
the value. Integers are often useful.

=item deprecation_reason

Reason if deprecated.

=item description

Description.

=back

=cut

has values => (
  is => 'ro',
  isa => Map[
    StrNameValid,
    Dict[
      value => Optional[Any],
      deprecation_reason => Optional[Str],
      description => Optional[Str],
    ]
  ],
  required => 1,
);

__PACKAGE__->meta->make_immutable();

1;
