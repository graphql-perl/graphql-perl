package GraphQL;

use 5.014;
use strict;
use warnings;

=head1 NAME

GraphQL - Perl implementation of GraphQL

=cut

our $VERSION = '0.21';

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
  use GraphQL::Execution qw(execute);

  my $schema = GraphQL::Schema->from_doc(<<'EOF');
  type Query {
    helloWorld: String
  }
  EOF
  post '/graphql' => sub {
    send_as JSON => execute(
      $schema,
      body_parameters->{query},
      { helloWorld => 'Hello world!' },
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

=head2 Introduction to GraphQL

GraphQL is a technology that lets clients talk to APIs via a single
endpoint, which acts as a single "source of the truth". This means clients
do not need to seek the whole picture from several APIs. Additionally,
it makes this efficient in network traffic, time, and programming effort:

=over

=item Network traffic

The request asks for exactly what it wants, which it gets, and no
more. No wasted traffic.

=item Time

It gets all the things it needs in one go, including any connected
resources, so it does not need to make several requests to fill its
information requirement.

=item Programming effort

With "fragments" that can be attached to user-interface components,
keeping track of what information a whole page needs to request can be
automated. See L<Relay|https://facebook.github.io/relay/> or
L<Apollo|http://dev.apollodata.com/> for more on this.

=back

=head2 Basic concepts

GraphQL implements a system featuring a L<schema|GraphQL::Schema>,
which features various classes of L<types|GraphQL::Type>, some of which
are L<objects|GraphQL::Type::Object>. Special objects provide the roots
of queries (mandatory), and mutations and subscriptions (both optional).

Objects have fields, each of which can be specified to take arguments,
and which have a return type. These are effectively the properties and/or
methods on the type. If they return an object, then a query can specify
subfields of that object, and so on - as alluded to in the "time-saving"
point above.

For more, see the JavaScript tutorial in L</"SEE ALSO">.

=head2 Hooking your system up to GraphQL

You will need to decide how to model your system in GraphQL terms. This
will involve deciding on what L<output object types|GraphQL::Type::Object>
you have, what fields they have, and what arguments and return-types
those fields have.

Additionally, you will need to design mutations if you want to be able
to update/create/delete data. This requires some thought for return types,
to ensure you can get all the information you need to proceed to avoid
extra round-trips.

The easiest way to achieve these things is to make a
L<GraphQL::Plugin::Convert> subclass, to encapsulate the specifics of
your system. See the documentation for further information.

Finally, you should consider whether you need "subscriptions". These
are designed to hook into WebSockets. Apollo has a L<JavaScript
module|https://github.com/apollographql/graphql-subscriptions> for this.

Specifying types and fields is straightforward. See L<the
document|GraphQL::Type::Library/FieldMapOutput> for how to make resolvers.

=head1 DEBUGGING

To debug, set environment variable C<GRAPHQL_DEBUG> to a true value.

=head1 EXPORT

None yet.

=head1 SEE ALSO

L<SQL::Translator::Producer::GraphQL> - produce GraphQL schemas from a L<DBIx::Class::Schema> (or in fact any SQL database)

L<GraphQL::Plugin::Convert::DBIC> - produce working GraphQL schema from
a L<DBIx::Class::Schema>

L<GraphQL::Plugin::Convert::OpenAPI> - produce working GraphQL schema
from an OpenAPI specification

L<Sample Mojolicious OpenAPI to GraphQL applet|https://github.com/graphql-perl/sample-mojolicious-openapi>

L<Sample Dancer 2 applet|https://github.com/graphql-perl/sample-dancer2>

L<Sample Mojolicious applet|https://github.com/graphql-perl/sample-mojolicious>

L<Dancer2::Plugin::GraphQL>

L<Mojolicious::Plugin::GraphQL>

L<http://facebook.github.io/graphql/> - GraphQL specification

L<http://graphql.org/graphql-js/> - Tutorial on the JavaScript version,
highly recommended.
L<Translation to
graphql-perl|http://blogs.perl.org/users/ed_j/2017/10/graphql-perl---graphql-js-tutorial-translation-to-graphql-perl-and-mojoliciousplugingraphql.html>.

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

Artur Khabibullin C<< <rtkh at cpan.org> >> contributed valuable ports
of the JavaScript tests.

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Ed J.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1;
