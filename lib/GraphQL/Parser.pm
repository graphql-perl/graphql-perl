package GraphQL::Parser;

use 5.014;
use strict;
use warnings;
use Moo;
use Return::Type;
use Types::Standard qw(Str Bool HashRef);
use Function::Parameters;

require Pegex::Parser;
require GraphQL::Grammar;
require Pegex::Tree::Wrap;

=head1 NAME

GraphQL::Parser - GraphQL language parser

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

  use GraphQL::Parser;
  my $parsed = GraphQL::Parser->parse(
    $source
  );

=head1 METHODS

=head2 parse

  GraphQL::Parser->parse($source, $noLocation);

=cut

method parse(Str $source, Bool $noLocation = undef) :ReturnType(HashRef) {
  my $parser = Pegex::Parser->new(
    grammar => GraphQL::Grammar->new,
    receiver => Pegex::Tree::Wrap->new,
  );
  my $input = Pegex::Input->new(string => $source);
  return $parser->parse($input);
}

__PACKAGE__->meta->make_immutable();

1;
