package GraphQL::Type;

use 5.014;
use strict;
use warnings;
use Moo;
use Types::Standard qw(Str);
use GraphQL::Utilities qw(StrNameValid);

our $VERSION = '0.02';

=head1 NAME

GraphQL::Type - Perl implementation

=head1 SYNOPSIS

    extends qw(GraphQL::Type);

=head1 DESCRIPTION

Superclass for other GraphQL type classes to inherit from.

=head1 ATTRIBUTES

=head2 name

=cut

has name => (is => 'ro', isa => StrNameValid, required => 1);

=head2 description

Optional description.

=cut

has description => (is => 'ro', isa => Str);

__PACKAGE__->meta->make_immutable();

1;
