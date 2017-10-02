# NAME

GraphQL - Perl implementation of GraphQL

# PROJECT STATUS

| OS      |  Build status |
|:-------:|--------------:|
| Linux   | [![Build Status](https://travis-ci.org/graphql-perl/graphql-perl.svg?branch=master)](https://travis-ci.org/graphql-perl/graphql-perl) |

[![CPAN version](https://badge.fury.io/pl/GraphQL.svg)](https://metacpan.org/pod/GraphQL)

# SYNOPSIS

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

The above is from [the sample Dancer 2 applet](https://github.com/graphql-perl/sample-dancer2).

# DESCRIPTION

This module is a port of the GraphQL reference implementation,
[graphql-js](https://github.com/graphql-js/graphql-js), to Perl 5.

See [GraphQL::Type](https://metacpan.org/pod/GraphQL::Type) for description of how to create GraphQL types.

# DEBUGGING

To debug, set environment variable `GRAPHQL_DEBUG` to a true value.

# EXPORT

None yet.

# SEE ALSO

[http://facebook.github.io/graphql/](http://facebook.github.io/graphql/) - GraphQL specification

[http://graphql.org/graphql-js/](http://graphql.org/graphql-js/) - Tutorial on the JavaScript version,
highly recommended.

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

# LICENSE AND COPYRIGHT

Copyright 2017 Ed J.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)
