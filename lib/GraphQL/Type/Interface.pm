package GraphQL::Type::Interface;

use 5.014;
use strict;
use warnings;
use Moo;
use Types::Standard qw(Str HashRef CodeRef);

=head1 NAME

GraphQL::Type::Interface - Perl implementation

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

  use GraphQL::Type::Interface;
  my $ImplementingType;
  my $InterfaceType = GraphQL::Type::Interface->new(
    name => 'Interface',
    fields => { fieldName => { type => 'GraphQLString' } },
    resolveType => sub {
      return $ImplementingType;
    },
  );

=head1 ATTRIBUTES

=head2 name

=cut

has 'name' => (is => 'ro', isa => Str, required => 1);

=head2 description

Optional description.

=cut

has 'description' => (is => 'ro', isa => Str);

=head2 fields

Hash-ref mapping fields to their types.

=cut

has 'fields' => (is => 'ro', isa => HashRef, required => 1);

=head2 resolveType

Optional code-ref to resolve types.

=cut

has 'resolveType' => (is => 'ro', isa => CodeRef);

__PACKAGE__->meta->make_immutable();

1;
