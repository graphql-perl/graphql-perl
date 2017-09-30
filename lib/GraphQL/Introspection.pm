package GraphQL::Introspection;

use 5.014;
use strict;
use warnings;
use base 'Exporter';

=head1 NAME

GraphQL::Introspection - Perl implementation of GraphQL

=cut

our $VERSION = '0.02';

our @EXPORT_OK = qw(
  $QUERY
);

=head1 SYNOPSIS

  use GraphQL::Introspection qw($QUERY);
  my $schema_data = GraphQL::Execution->execute($schema, $QUERY);

=head1 DESCRIPTION

Provides infrastructure implementing GraphQL's introspection.

=head1 EXPORT

=head2 $QUERY

The GraphQL query to introspect the schema.

=cut

our $QUERY = '
  query IntrospectionQuery {
    __schema {
      queryType { name }
      mutationType { name }
      subscriptionType { name }
      types {
        ...FullType
      }
      directives {
        name
        description
        locations
        args {
          ...InputValue
        }
      }
    }
  }
  fragment FullType on __Type {
    kind
    name
    description
    fields(includeDeprecated: true) {
      name
      description
      args {
        ...InputValue
      }
      type {
        ...TypeRef
      }
      isDeprecated
      deprecationReason
    }
    inputFields {
      ...InputValue
    }
    interfaces {
      ...TypeRef
    }
    enumValues(includeDeprecated: true) {
      name
      description
      isDeprecated
      deprecationReason
    }
    possibleTypes {
      ...TypeRef
    }
  }
  fragment InputValue on __InputValue {
    name
    description
    type { ...TypeRef }
    defaultValue
  }
  fragment TypeRef on __Type {
    kind
    name
    ofType {
      kind
      name
      ofType {
        kind
        name
        ofType {
          kind
          name
          ofType {
            kind
            name
            ofType {
              kind
              name
              ofType {
                kind
                name
                ofType {
                  kind
                  name
                }
              }
            }
          }
        }
      }
    }
  }
';

1;
