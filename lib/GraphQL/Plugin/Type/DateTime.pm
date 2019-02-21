package GraphQL::Plugin::Type::DateTime;

use strict;
use warnings;
use GraphQL::Type::Scalar;
use GraphQL::Plugin::Type;
use DateTime::Format::ISO8601;

=head1 NAME

GraphQL::Plugin::Type::DateTime - GraphQL DateTime scalar type

=head1 SYNOPSIS

  use GraphQL::Schema;
  use GraphQL::Plugin::Type::DateTime;
  use GraphQL::Execution qw(execute);
  my $schema = GraphQL::Schema->from_doc(<<'EOF');
  type Query { dateTimeNow: DateTime }
  EOF
  post '/graphql' => sub {
    send_as JSON => execute(
      $schema,
      body_parameters->{query},
      { dateTimeNow => sub { DateTime->now } },
      undef,
      body_parameters->{variables},
      body_parameters->{operationName},
      undef,
    );
  };

=head1 DESCRIPTION

Implements a non-standard GraphQL scalar type that represents
a point in time, canonically represented in ISO 8601 format,
e.g. C<20171114T07:41:10>.

=cut

my $iso8601 = DateTime::Format::ISO8601->new;
GraphQL::Plugin::Type->register(
  GraphQL::Type::Scalar->new(
    name => 'DateTime',
    description =>
      'The `DateTime` scalar type represents a point in time. ' .
      'Canonically represented using ISO 8601 format, e.g. 20171114T07:41:10, '.
      'which is 14 November 2017 at 07:41am.',
    serialize => sub { return if !defined $_[0]; $_[0].'' },
    parse_value => sub { return if !defined $_[0]; $iso8601->parse_datetime(@_); },
  )
);

1;
