package GraphQL::Schema;

use 5.014;
use strict;
use warnings;
use Moo;
use Types::Standard qw(Str InstanceOf);

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

has 'query' => (is => 'ro', isa => InstanceOf['GraphQL::Type::Object'], required => 1);

__PACKAGE__->meta->make_immutable();

1;
