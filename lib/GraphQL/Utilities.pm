package GraphQL::Utilities;

use 5.014;
use strict;
use warnings;
use Type::Library
  -base,
  -declare => qw( StrNameValid FieldMapInput );
use Type::Utils -all;
BEGIN { extends "Types::Standard" };
use Exporter qw(import);

our $VERSION = '0.02';
our @EXPORT_OK = qw(
  StrNameValid
  FieldMapInput
);

=head1 NAME

GraphQL::Utilities - GraphQL utility functions

=head1 SYNOPSIS

    use GraphQL::Utilities qw(StrNameValid);
    has name => (is => 'ro', isa => StrNameValid, required => 1);

=head1 FUNCTIONS

=head2 StrNameValid

If called with a string that is not a valid GraphQL name, will throw
an exception. Suitable for passing to an C<isa> constraint in L<Moo>.

=cut

declare "StrNameValid", as StrMatch[ qr/^[_a-zA-Z][_a-zA-Z0-9]*$/ ];

=head2 FieldMapInput

Hash-ref mapping field names to a hash-ref description. Description keys,
all optional:

=over

=item type

GraphQL input type for the field.

=item default_value

Default value for this argument if none supplied. Must be same type as
the C<type>.

=item description

Description.

=back

=cut

declare "FieldMapInput", as Map[
  StrNameValid,
  Dict[
    type => ConsumerOf['GraphQL::Role::Input'],
    # TODO: change Any to check that is same as supplied "type". Possibly
    # with builder?
    default_value => Optional[Any],
    description => Optional[Str],
  ]
];

=head1 AUTHOR

Ed J, C<< <etj at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-graphql at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=GraphQL>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc GraphQL

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=GraphQL>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/GraphQL>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/GraphQL>

=item * Search CPAN

L<http://search.cpan.org/dist/GraphQL/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Ed J.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;
