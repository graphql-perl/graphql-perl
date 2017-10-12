package GraphQL::Language::Parser;

use 5.014;
use strict;
use warnings;
use base 'Pegex::Parser';
use Return::Type;
use Types::Standard -all;
use Function::Parameters;
use GraphQL::Language::Grammar;
use GraphQL::Language::Receiver;

our $VERSION = '0.02';

=head1 NAME

GraphQL::Language::Parser - GraphQL Pegex parser

=head1 SYNOPSIS

  use GraphQL::Language::Parser;
  my $parsed = GraphQL::Language::Parser->parse(
    $source
  );

=head1 DESCRIPTION

Provides both an outside-accessible point of entry into the GraphQL
parser (see above), and a subclass of L<Pegex::Parser> to parse a document
into an AST usable by GraphQL.

=head1 METHODS

=head2 parse

  GraphQL::Language::Parser->parse($source, $noLocation);

B<NB> that unlike in C<Pegex::Parser> this is a class method, not an instance
method. This achieves hiding of Pegex implementation details.

=cut

my $GRAMMAR = GraphQL::Language::Grammar->new; # singleton
method parse(Str $source, Bool $noLocation = undef) :ReturnType(ArrayRef) {
  my $parser = $self->SUPER::new(
    grammar => $GRAMMAR,
    receiver => GraphQL::Language::Receiver->new,
  );
  my $input = Pegex::Input->new(string => $source);
  return $parser->SUPER::parse($input);
}

1;
