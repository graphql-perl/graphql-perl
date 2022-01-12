# NAME

GraphQL - Perl implementation of GraphQL

# PROJECT STATUS

| OS      |  Build status |
|:-------:|--------------:|
| Linux   | [![Build Status](https://travis-ci.org/graphql-perl/graphql-perl.svg?branch=master)](https://travis-ci.org/graphql-perl/graphql-perl) |

[![CPAN version](https://badge.fury.io/pl/GraphQL.svg)](https://metacpan.org/pod/GraphQL) [![Coverage Status](https://coveralls.io/repos/github/graphql-perl/graphql-perl/badge.svg?branch=master)](https://coveralls.io/github/graphql-perl/graphql-perl?branch=master)

# SYNOPSIS

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

The above is from [the sample Dancer 2 applet](https://github.com/graphql-perl/sample-dancer2).

# DESCRIPTION

This module is a port of the GraphQL reference implementation,
[graphql-js](https://github.com/graphql-js/graphql-js), to Perl 5.

It now supports Promises, allowing asynchronous operation. See
[Mojolicious::Plugin::GraphQL](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AGraphQL) for an example of how to take advantage
of this.

As of 0.39, supports GraphQL subscriptions.

See [GraphQL::Type](https://metacpan.org/pod/GraphQL%3A%3AType) for description of how to create GraphQL types.

## Introduction to GraphQL

GraphQL is a technology that lets clients talk to APIs via a single
endpoint, which acts as a single "source of the truth". This means clients
do not need to seek the whole picture from several APIs. Additionally,
it makes this efficient in network traffic, time, and programming effort:

- Network traffic

    The request asks for exactly what it wants, which it gets, and no
    more. No wasted traffic.

- Time

    It gets all the things it needs in one go, including any connected
    resources, so it does not need to make several requests to fill its
    information requirement.

- Programming effort

    With "fragments" that can be attached to user-interface components,
    keeping track of what information a whole page needs to request can be
    automated. See [Relay](https://facebook.github.io/relay/) or
    [Apollo](http://dev.apollodata.com/) for more on this.

## Basic concepts

GraphQL implements a system featuring a [schema](https://metacpan.org/pod/GraphQL%3A%3ASchema),
which features various classes of [types](https://metacpan.org/pod/GraphQL%3A%3AType), some of which
are [objects](https://metacpan.org/pod/GraphQL%3A%3AType%3A%3AObject). Special objects provide the roots
of queries (mandatory), and mutations and subscriptions (both optional).

Objects have fields, each of which can be specified to take arguments,
and which have a return type. These are effectively the properties and/or
methods on the type. If they return an object, then a query can specify
subfields of that object, and so on - as alluded to in the "time-saving"
point above.

For more, see the JavaScript tutorial in ["SEE ALSO"](#see-also).

## Hooking your system up to GraphQL

You will need to decide how to model your system in GraphQL terms. This
will involve deciding on what [output object types](https://metacpan.org/pod/GraphQL%3A%3AType%3A%3AObject)
you have, what fields they have, and what arguments and return-types
those fields have.

Additionally, you will need to design mutations if you want to be able
to update/create/delete data. This requires some thought for return types,
to ensure you can get all the information you need to proceed to avoid
extra round-trips.

The easiest way to achieve these things is to make a
[GraphQL::Plugin::Convert](https://metacpan.org/pod/GraphQL%3A%3APlugin%3A%3AConvert) subclass, to encapsulate the specifics of
your system. See the documentation for further information.

Finally, you should consider whether you need "subscriptions". These
are designed to hook into WebSockets. Apollo has a [JavaScript
module](https://github.com/apollographql/graphql-subscriptions) for this.

Specifying types and fields is straightforward. See [the
document](https://metacpan.org/pod/GraphQL%3A%3AType%3A%3ALibrary#FieldMapOutput) for how to make resolvers.

# DEBUGGING

To debug, set environment variable `GRAPHQL_DEBUG` to a true value.

# EXPORT

None yet.

# SEE ALSO

[SQL::Translator::Producer::GraphQL](https://metacpan.org/pod/SQL%3A%3ATranslator%3A%3AProducer%3A%3AGraphQL) - produce GraphQL schemas from a [DBIx::Class::Schema](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3ASchema) (or in fact any SQL database)

[GraphQL::Plugin::Convert::DBIC](https://metacpan.org/pod/GraphQL%3A%3APlugin%3A%3AConvert%3A%3ADBIC) - produce working GraphQL schema from
a [DBIx::Class::Schema](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3ASchema)

[GraphQL::Plugin::Convert::OpenAPI](https://metacpan.org/pod/GraphQL%3A%3APlugin%3A%3AConvert%3A%3AOpenAPI) - produce working GraphQL schema
from an OpenAPI specification

[Sample Mojolicious OpenAPI to GraphQL applet](https://github.com/graphql-perl/sample-mojolicious-openapi)

[Sample Dancer 2 applet](https://github.com/graphql-perl/sample-dancer2)

[Sample Mojolicious applet](https://github.com/graphql-perl/sample-mojolicious)

[Dancer2::Plugin::GraphQL](https://metacpan.org/pod/Dancer2%3A%3APlugin%3A%3AGraphQL)

[Mojolicious::Plugin::GraphQL](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AGraphQL)

[http://facebook.github.io/graphql/](http://facebook.github.io/graphql/) - GraphQL specification

[http://graphql.org/graphql-js/](http://graphql.org/graphql-js/) - Tutorial on the JavaScript version,
highly recommended.
[Translation to
graphql-perl](http://blogs.perl.org/users/ed_j/2017/10/graphql-perl---graphql-js-tutorial-translation-to-graphql-perl-and-mojoliciousplugingraphql.html).

# AUTHOR

Ed J, `<etj at cpan.org>`

# BUGS

Please report any bugs or feature requests on
[https://github.com/graphql-perl/graphql-perl/issues](https://github.com/graphql-perl/graphql-perl/issues).

Or, if you prefer email and/or RT: to `bug-graphql
at rt.cpan.org`, or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=GraphQL](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=GraphQL). I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

# ACKNOWLEDGEMENTS

The creation of this work has been sponsored by Perl Careers:
[https://perl.careers/](https://perl.careers/).

Artur Khabibullin `<rtkh at cpan.org>` contributed valuable ports
of the JavaScript tests.

The creation of the subscriptions functionality in this work has been
sponsored by Sanctus.app: [https://sanctus.app](https://sanctus.app).

# LICENSE AND COPYRIGHT

Copyright 2017 Ed J.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)
