package GraphQL;

use 5.014;
use strict;
use warnings;

=head1 NAME

GraphQL - Perl implementation of GraphQL

=cut

our $VERSION = '0.08';

=begin markdown

# PROJECT STATUS

| OS      |  Build status |
|:-------:|--------------:|
| Linux   | [![Build Status](https://travis-ci.org/graphql-perl/graphql-perl.svg?branch=master)](https://travis-ci.org/graphql-perl/graphql-perl) |

[![CPAN version](https://badge.fury.io/pl/GraphQL.svg)](https://metacpan.org/pod/GraphQL)

=end markdown

=head1 SYNOPSIS

  use GraphQL::Schema;
  use GraphQL::Type::Object;
  use GraphQL::Type::Scalar qw($String);
  use GraphQL::Execution;

  my $schema = GraphQL::Schema->new(query => GraphQL::Type::Object->new(
    name => 'QueryRoot',
    fields => {
      helloWorld => { type => $String, resolve => sub { 'Hello world!' } },
    },
  ));
  post '/graphql' => sub {
    send_as JSON => GraphQL::Execution->execute(
      $schema,
      body_parameters->{query},
      undef,
      undef,
      body_parameters->{variables},
      body_parameters->{operationName},
      undef,
    );
  };

The above is from L<the sample Dancer 2 applet|https://github.com/graphql-perl/sample-dancer2>.

=head1 DESCRIPTION

This module is a port of the GraphQL reference implementation,
L<graphql-js|https://github.com/graphql-js/graphql-js>, to Perl 5.

See L<GraphQL::Type> for description of how to create GraphQL types.

=head1 DEBUGGING

To debug, set environment variable C<GRAPHQL_DEBUG> to a true value.

=head1 EXPORT

None yet.

=head1 SEE ALSO

L<http://facebook.github.io/graphql/> - GraphQL specification

L<http://graphql.org/graphql-js/> - Tutorial on the JavaScript version,
highly recommended.

=head1 AUTHOR

Ed J, C<< <etj at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests on
L<https://github.com/graphql-perl/graphql-perl/issues>.

Or, if you prefer email and/or RT: to C<bug-graphql
at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=GraphQL>. I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 ACKNOWLEDGEMENTS

The creation of this work has been sponsored by Perl Careers:
L<https://perl.careers/>.

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Ed J.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1;
