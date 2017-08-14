package GraphQL::Type::Interface;

use 5.014;
use strict;
use warnings;
use Moo;
use Types::Standard qw(Str HashRef CodeRef);
use GraphQL::Utilities qw(assert_valid_name);

our $VERSION = '0.02';

=head1 NAME

GraphQL::Type::Interface - Perl implementation of a GraphQL interface type

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

has 'name' => (is => 'ro', isa => \&assert_valid_name, required => 1);

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
