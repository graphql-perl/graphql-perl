package GraphQL::Type::List;

use 5.014;
use strict;
use warnings;
use Moo;
use Types::Standard -all;
use GraphQL::Type::Library -all;
use GraphQL::MaybeTypeCheck;
use GraphQL::Debug qw(_debug);
extends qw(GraphQL::Type);
with qw(GraphQL::Role::Nullable);

# A-ha
my @TAKE_ON_ME = qw(
  GraphQL::Role::Input
  GraphQL::Role::Output
);

our $VERSION = '0.02';
use constant DEBUG => $ENV{GRAPHQL_DEBUG};

=head1 NAME

GraphQL::Type::List - GraphQL type that is a list of another type

=head1 SYNOPSIS

  use GraphQL::Type::List;
  my $type = GraphQL::Type::List->new(of => $other_type);

=head1 DESCRIPTION

Type that is a wrapper for the type it is a list of. If the wrapped type
has any of these roles, it will assume them: L<GraphQL::Role::Input>,
L<GraphQL::Role::Output>. It is always L<GraphQL::Role::Nullable>.

=head1 ATTRIBUTES

=head2 of

GraphQL type object of which this is a list.

=cut

has of => (
  is => 'ro',
  isa => InstanceOf['GraphQL::Type'],
  required => 1,
  handles => [ qw(name) ],
);

=head1 METHODS

=head2 BUILD

L<Moo> method that applies the relevant roles.

=cut

sub BUILD {
  my ($self, $args) = @_;
  my $of = $self->of;
  Role::Tiny->apply_roles_to_object($self, grep $of->DOES($_), @TAKE_ON_ME);
}

=head2 to_string

Part of serialisation.

=cut

has to_string => (is => 'lazy', isa => Str, init_arg => undef, builder => sub {
  my ($self) = @_;
  '[' . $self->of->to_string . ']';
});

=head2 is_valid

True if given Perl array-ref is a valid value for this type.

=cut

method is_valid(Any $item) :ReturnType(Bool) {
  return 1 if !defined $item;
  my $of = $self->of;
  return if grep !$of->is_valid($_), @{ $self->uplift($item) };
  1;
}

=head2 uplift

Turn given Perl entity into valid value for this type if possible.
Mainly to promote single value into a list if type dictates.

=cut

# This is a crime against God. graphql-js does it however.
method uplift(Any $item) :ReturnType(Any) {
  return $item if ref($item) eq 'ARRAY' or !defined $item;
  [ $item ];
}

method graphql_to_perl(Any $item) :ReturnType(Maybe[ArrayRef]) {
  return $item if !defined $item;
  $item = $self->uplift($item);
  my $of = $self->of;
  my $i = 0;
  my @errors;
  my @values = map {
    my $value = eval { $of->graphql_to_perl($_) };
    push @errors, qq{In element #$i: $@} if $@;
    $i++;
    $value;
  } @$item;
  die @errors if @errors;
  \@values;
}

method perl_to_graphql(Any $item) :ReturnType(Maybe[ArrayRef]) {
  return $item if !defined $item;
  $item = $self->uplift($item);
  my $of = $self->of;
  my $i = 0;
  my @errors;
  my @values = map {
    my $value = eval { $of->perl_to_graphql($_) };
    push @errors, qq{In element #$i: $@} if $@;
    $i++;
    $value;
  } @$item;
  die @errors if @errors;
  \@values;
}

method _complete_value(
  HashRef $context,
  ArrayRef[HashRef] $nodes,
  HashRef $info,
  ArrayRef $path,
  ArrayRef $result,
) {
  # TODO promise stuff
  my $item_type = $self->of;
  my $index = 0;
  my @errors;
  my @completed = map GraphQL::Execution::_complete_value_catching_error(
    $context,
    $item_type,
    $nodes,
    $info,
    [ @$path, $index++ ],
    $_,
  ), @$result;
  DEBUG and _debug("List._complete_value(done)", \@completed);
  (grep is_Promise($_), @completed)
    ? _promise_for_list($context, \@completed)
    : _merge_list(\@completed);
}

fun _merge_list(
  ArrayRef[ExecutionPartialResult] $list,
) :ReturnType(ExecutionPartialResult) {
  DEBUG and _debug("List._merge_list", $list);
  my @errors = map @{ $_->{errors} || [] }, @$list;
  my @data = map $_->{data}, @$list;
  DEBUG and _debug("List._merge_list(after)", \@data, \@errors);
  +{ data => \@data, @errors ? (errors => \@errors) : () };
}

fun _promise_for_list(
  HashRef $context,
  ArrayRef $list,
) :ReturnType(Promise) {
  DEBUG and _debug('_promise_for_list', $list);
  die "Given a promise in list but no PromiseCode given\n"
    if !$context->{promise_code};
  return $context->{promise_code}{all}->(@$list)->then(sub {
    DEBUG and _debug('_promise_for_list(all)', @_);
    _merge_list([ map $_->[0], @_ ]);
  });
}

=head2 name

The C<name> of the type this object is a list of.

=cut

__PACKAGE__->meta->make_immutable();

1;
