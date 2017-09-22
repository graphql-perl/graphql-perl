package GraphQL::Role::HashMappable;

use 5.014;
use strict;
use warnings;
use Moo::Role;
use Types::Standard -all;
use Function::Parameters;
use Return::Type;

our $VERSION = '0.02';

=head1 NAME

GraphQL::Role::HashMappable - GraphQL object role

=head1 SYNOPSIS

  with qw(GraphQL::Role::HashMappable);

  # or runtime
  Role::Tiny->apply_roles_to_object($foo, qw(GraphQL::Role::HashMappable));

=head1 DESCRIPTION

Provides method for mapping code over a hash-ref.

=head1 METHODS

=head2 hashmap

Given a hash-ref, returns a modified copy of the data. Returns undef if
given that. Parameters:

=over

=item $item

Hash-ref.

=item $keys

Array-ref of the valid keys for this hash.

=item $code

Code-ref.

=back

Each value will be the original value returned by the given code-ref,
which is called with C<$keyname>, C<$value>. Will call the code for all
given keys, but not copy over any values not existing in original item.

If code throws an exception, the message will have added to it information
about which data element caused it.

=cut

method hashmap(Maybe[HashRef] $item, ArrayRef $keys, CodeRef $code) :ReturnType(Maybe[HashRef]) {
  return $item if !defined $item;
  # if just return { map ... }, fails bizarrely
  my %newvalue = map {
    my @pair = eval { ($_ => scalar $code->($_, $item->{$_})) };
    die qq{In field "$_": $@} if $@;
    exists $item->{$_} ? @pair : ();
  } @$keys;
  \%newvalue;
}

__PACKAGE__->meta->make_immutable();

1;
