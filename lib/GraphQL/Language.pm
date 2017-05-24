package GraphQL::Language;

use 5.006;
use strict;
use warnings;
use Moo;
use Return::Type;
use Types::Standard qw(Str Bool);
use Function::Parameters;

=head1 NAME

GraphQL::Language - GraphQL language parser

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

  use GraphQL::Language;
  my $parsed = GraphQL::Language->parse(
    $source
  );

=head1 METHODS

=head2 parse

  GraphQL::Language->parse($source, $noLocation);

=cut

method parse(Str $source, Bool $noLocation = undef) :ReturnType(Str) {
  return 'Yo';
}

__PACKAGE__->meta->make_immutable();

1;
