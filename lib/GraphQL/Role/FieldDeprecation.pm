package GraphQL::Role::FieldDeprecation;

use 5.014;
use strict;
use warnings;
use Moo::Role;

our $VERSION = '0.02';

=head1 NAME

GraphQL::Role::FieldDeprecation - GraphQL object role implementing deprecation of fields

=head1 SYNOPSIS

  with qw(GraphQL::Role::FieldDeprecation);

  # or runtime
  Role::Tiny->apply_roles_to_object($foo, qw(GraphQL::Role::FieldDeprecation));

=head1 DESCRIPTION

Implements deprecation of fields.

=cut

has _fields_deprecation_applied => (is => 'rw');
sub _fields_deprecation_apply {
  my ($self, $key) = @_;
  return if $self->_fields_deprecation_applied;
  my $v = $self->{$key} = { %{$self->{$key}} }; # copy on write
  for my $name (keys %$v) {
    if (defined $v->{$name}{deprecation_reason}) {
      $v->{$name} = { %{$v->{$name}}, is_deprecated => 1 }; # copy on write
    }
  }
  $self->_fields_deprecation_applied(1);
};

__PACKAGE__->meta->make_immutable();

1;
