package GraphQL::MaybeTypeCheck;

use 5.014;
use strict;
use warnings;

use Attribute::Handlers;
use Devel::StrictMode;
use Import::Into;


=head1 NAME

GraphQL::MaybeTypeCheck - Conditional type-checking at runtime

=head1 SYNOPSIS

  use GraphQL::MaybeTypeCheck;

  method foo(
    $arg1 Str,
    $arg2 Int
  ) :ReturnType(Map[Str, Int]) {
    # ...
  }

=head1 DESCRIPTION

This module B<optionally> enabled type-checking in the caller as implemented by
L<Function::Parameters> and L<Return::Type> depending on whether L<Devel::StrictMode>
is activated.

=head3 C<Devel::StrictMode> ON

When L<Devel::StrictMode> is active, this module will import L<Function::Parameters>
into the caller with it's default configuration. As of writing, this includes
checking both argument count and type.

When in strict mode this also C<require>s L<Return::Type> which registers the
C<ReturnType> attribute.

=head3 C<Devel::StrictMode> OFF

When strict mode is inactive this module still imports C<Function::Parameters>
into the caller however it sets C<fun> and C<method> to L<lax mode|Function::Parameters/function_lax> and disables
argument type checking.

This also installs a no-op C<ReturnType> attribute so the existing syntax isn't
broken.

=cut

sub ReturnType : ATTR(CODE) {
  my ($package, $symbol, $referent, $attr, $data) = @_;

  # If strict mode is enabled, wrap the sub so the return type is checked
  if (STRICT) {
    my %args = (@$data % 2) ? (scalar => @$data) : @$data;
    Return::Type->wrap_sub($referent, %args);
  }
}

sub import {
  my $caller = caller;

  # Here we push ourselves onto @ISA of the caller so they use our ReturnType
  # attribute which conditionally wraps the target sub depending on whetther
  # strict mode is enabled or not.
  {
    no strict 'refs';
    push @{"${caller}::ISA"}, __PACKAGE__;
  }

  if (STRICT) {
    Function::Parameters->import::into($caller, ':strict');
    require Return::Type;
  }
  else {
    Function::Parameters->import::into($caller, {
      fun    => {defaults => 'function_lax', check_argument_types => 0},
      method => {defaults => 'method_lax',   check_argument_types => 0},
    });
  }
}

1;