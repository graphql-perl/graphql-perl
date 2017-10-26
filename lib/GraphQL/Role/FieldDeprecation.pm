package GraphQL::Role::FieldDeprecation;

use 5.014;
use strict;
use warnings;
use Moo::Role;
use Function::Parameters;
use Types::Standard -all;
use JSON::MaybeXS;

our $VERSION = '0.02';
my $JSON_noutf8 = JSON::MaybeXS->new->utf8(0)->allow_nonref;

=head1 NAME

GraphQL::Role::FieldDeprecation - object role implementing deprecation of fields

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
  $self->_fields_deprecation_applied(1);
  my $v = $self->{$key} = { %{$self->{$key}} }; # copy on write
  for my $name (keys %$v) {
    if (defined $v->{$name}{deprecation_reason}) {
      $v->{$name} = { %{$v->{$name}}, is_deprecated => 1 }; # copy on write
    }
  }
};

method _from_ast_field_deprecate(
  Str $key,
  HashRef $values,
) {
  my $value = +{ %{$values->{$key}} };
  my $directives = delete $value->{directives}; # ok as copy
  return $values unless $directives and @$directives;
  my ($deprecated) = grep $_->{name} eq 'deprecated', @$directives;
  return $values unless $deprecated;
  my $reason = $deprecated->{arguments}{reason}
    // $GraphQL::Directive::DEPRECATED->args->{reason}{default_value};
  +{
    %$values,
    $key => { %$value, deprecation_reason => $reason },
  };
}

method _to_doc_field_deprecate(
  Str $line,
  HashRef $value,
) {
  return $line if !$value->{is_deprecated};
  $line .= ' @deprecated';
  $line .= '(reason: ' . $JSON_noutf8->encode($value->{deprecation_reason}) . ')'
    if $value->{deprecation_reason} ne
      $GraphQL::Directive::DEPRECATED->args->{reason}{default_value};
  $line;
}

__PACKAGE__->meta->make_immutable();

1;
