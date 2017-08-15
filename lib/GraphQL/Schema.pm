package GraphQL::Schema;

use 5.014;
use strict;
use warnings;
use Moo;
use Types::Standard qw(Str InstanceOf ArrayRef ConsumerOf);

our $VERSION = '0.02';

=head1 NAME

GraphQL::Schema - GraphQL schema object

=head1 SYNOPSIS

  use GraphQL::Schema;
  use GraphQL::Type::Object;
  my $schema = GraphQL::Schema->new(
    query => GraphQL::Type::Object->new(
      name => 'Query',
      fields => {
        getObject => {
          type => $interfaceType,
          resolve => sub {
            return {};
          }
        }
      }
    )
  );

=head1 DESCRIPTION

Class implementing GraphQL schema.

=head1 ATTRIBUTES

=head2 query

=cut

has query => (is => 'ro', isa => InstanceOf['GraphQL::Type::Object'], required => 1);

=head2 mutation

=cut

has mutation => (is => 'ro', isa => InstanceOf['GraphQL::Type::Object']);

=head2 subscription

=cut

has subscription => (is => 'ro', isa => InstanceOf['GraphQL::Type::Object']);

=head2 types

=cut

has types => (is => 'ro', isa => ArrayRef[ConsumerOf['GraphQL::Type::Named']]);

=head2 directives

=cut

has directives => (is => 'ro', isa => ArrayRef[InstanceOf['GraphQL::Directive']]);

__PACKAGE__->meta->make_immutable();

1;
