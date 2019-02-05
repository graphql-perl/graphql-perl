package GraphQL::Schema;

use 5.014;
use strict;
use warnings;
use Moo;
use Types::Standard -all;
use GraphQL::Type::Library -all;
use Return::Type;
use Function::Parameters;
use GraphQL::Debug qw(_debug);
use GraphQL::Directive;
use GraphQL::Introspection qw($SCHEMA_META_TYPE);
use GraphQL::Type::Scalar qw($Int $Float $String $Boolean $ID $DateTime);
use GraphQL::Language::Parser qw(parse);
use Module::Runtime qw(require_module);
use Exporter 'import';

our $VERSION = '0.02';
our @EXPORT_OK = qw(lookup_type);
use constant DEBUG => $ENV{GRAPHQL_DEBUG};
my %BUILTIN2TYPE = map { ($_->name => $_) } ($Int, $Float, $String, $Boolean, $ID, $DateTime);
my @TYPE_ATTRS = qw(query mutation subscription);

=head1 NAME

GraphQL::Schema - GraphQL schema object

=head1 SYNOPSIS

  use GraphQL::Schema;
  use GraphQL::Type::Object;
  my $schema = GraphQL::Schema->new(
    query => GraphQL::Type::Object->new(
      name => 'Query',
      fields => {
        getObject => {
          type => $interfaceType,
          resolve => sub {
            return {};
          }
        }
      }
    )
  );

=head1 DESCRIPTION

Class implementing GraphQL schema.

=head1 ATTRIBUTES

=head2 query

=cut

has query => (is => 'ro', isa => InstanceOf['GraphQL::Type::Object'], required => 1);

=head2 mutation

=cut

has mutation => (is => 'ro', isa => InstanceOf['GraphQL::Type::Object']);

=head2 subscription

=cut

has subscription => (is => 'ro', isa => InstanceOf['GraphQL::Type::Object']);

=head2 types

=cut

has types => (
  is => 'ro',
  isa => ArrayRef[ConsumerOf['GraphQL::Role::Named']],
  default => sub { [] },
);

=head2 directives

=cut

has directives => (
  is => 'ro',
  isa => ArrayRef[InstanceOf['GraphQL::Directive']],
  default => sub { \@GraphQL::Directive::SPECIFIED_DIRECTIVES },
);

=head1 METHODS

=head2 name2type

In this schema, returns a hash-ref mapping all types' names to their
type object.

=cut

has name2type => (is => 'lazy', isa => Map[StrNameValid, ConsumerOf['GraphQL::Role::Named']]);
sub _build_name2type {
  my ($self) = @_;
  my @types = grep $_, (map $self->$_, @TYPE_ATTRS), $SCHEMA_META_TYPE;
  push @types, @{ $self->types || [] };
  my %name2type;
  map _expand_type(\%name2type, $_), @types;
  \%name2type;
}

=head2 get_possible_types($abstract_type)

In this schema, get all of either the implementation types
(if interface) or possible types (if union) of the C<$abstract_type>.

=cut

fun _expand_type(
  (Map[StrNameValid, ConsumerOf['GraphQL::Role::Named']]) $map,
  (InstanceOf['GraphQL::Type']) $type,
) :ReturnType(ArrayRef[ConsumerOf['GraphQL::Role::Named']]) {
  return _expand_type($map, $type->of) if $type->can('of');
  my $name = $type->name if $type->can('name');
  return [] if $name and $map->{$name} and $map->{$name} == $type; # seen
  die "Duplicate type $name" if $map->{$name};
  $map->{$name} = $type;
  my @types;
  push @types, ($type, map @{ _expand_type($map, $_) }, @{ $type->interfaces || [] })
    if $type->isa('GraphQL::Type::Object');
  push @types, ($type, map @{ _expand_type($map, $_) }, @{ $type->get_types })
    if $type->isa('GraphQL::Type::Union');
  if (grep $type->DOES($_), qw(GraphQL::Role::FieldsInput GraphQL::Role::FieldsOutput)) {
    my $fields = $type->fields||{};
    push @types, map {
      map @{ _expand_type($map, $_->{type}) }, $_, values %{ $_->{args}||{} }
    } values %$fields;
  }
  DEBUG and _debug('_expand_type', \@types);
  \@types;
}

has _interface2types => (is => 'lazy', isa => Map[StrNameValid, ArrayRef[InstanceOf['GraphQL::Type::Object']]]);
sub _build__interface2types {
  my ($self) = @_;
  my $name2type = $self->name2type||{};
  my %interface2types;
  map {
    my $o = $_;
    map {
      push @{$interface2types{$_->name}}, $o;
      # TODO assert_object_implements_interface
    } @{ $o->interfaces||[] };
  } grep $_->isa('GraphQL::Type::Object'), values %$name2type;
  \%interface2types;
}

method get_possible_types(
  (ConsumerOf['GraphQL::Role::Abstract']) $abstract_type
) :ReturnType(ArrayRef[InstanceOf['GraphQL::Type::Object']]) {
  return $abstract_type->get_types if $abstract_type->isa('GraphQL::Type::Union');
  $self->_interface2types->{$abstract_type->name} || [];
}

=head2 is_possible_type($abstract_type, $possible_type)

In this schema, is the given C<$possible_type> either an implementation
(if interface) or a possibility (if union) of the C<$abstract_type>?

=cut

has _possible_type_map => (is => 'rw', isa => Map[StrNameValid, Map[StrNameValid, Bool]]);
method is_possible_type(
  (ConsumerOf['GraphQL::Role::Abstract']) $abstract_type,
  (InstanceOf['GraphQL::Type::Object']) $possible_type,
) :ReturnType(Bool) {
  my $map = $self->_possible_type_map || {};
  return $map->{$abstract_type->name}{$possible_type->name}
    if $map->{$abstract_type->name}; # we know about the abstract_type
  my @possibles = @{ $self->get_possible_types($abstract_type)||[] };
  die <<EOF if !@possibles;
Could not find possible implementing types for @{[$abstract_type->name]}
in schema. Check that schema.types is defined and is an array of
all possible types in the schema.
EOF
  $map->{$abstract_type->name} = { map { ($_->name => 1) } @possibles };
  $self->_possible_type_map($map);
  $map->{$abstract_type->name}{$possible_type->name};
}

=head2 assert_object_implements_interface($type, $iface)

In this schema, does the given C<$type> implement interface C<$iface>? If
not, throw exception.

=cut

method assert_object_implements_interface(
  (ConsumerOf['GraphQL::Role::Abstract']) $abstract_type,
  (InstanceOf['GraphQL::Type::Object']) $possible_type,
) {
  my @types = @{ $self->types };
  return;
}

=head2 from_ast($ast[, \%kind2class])

Class method. Takes AST (array-ref of hash-refs) made by
L<GraphQL::Language::Parser/parse> and returns a schema object. Will
not be a complete schema since it will have only default resolvers.

If C<\%kind2class> is given, it will override the default
mapping of SDL keywords to Perl classes. This is probably most
useful for L<GraphQL::Type::Object>. The default is available as
C<%GraphQL::Schema::KIND2CLASS>. E.g.

  my $schema = GraphQL::Schema->from_ast(
    $doc,
    { %GraphQL::Schema::KIND2CLASS, type => 'GraphQL::Type::Object::DBIC' }
  );

=cut

our %KIND2CLASS = qw(
  type GraphQL::Type::Object
  enum GraphQL::Type::Enum
  interface GraphQL::Type::Interface
  union GraphQL::Type::Union
  scalar GraphQL::Type::Scalar
  input GraphQL::Type::InputObject
);
my %CLASS2KIND = reverse %KIND2CLASS;
method from_ast(
  ArrayRef[HashRef] $ast,
  HashRef $kind2class = \%KIND2CLASS,
) :ReturnType(InstanceOf[__PACKAGE__]) {
  DEBUG and _debug('Schema.from_ast', $ast);
  my @type_nodes = grep $kind2class->{$_->{kind}}, @$ast;
  my ($schema_node, $e) = grep $_->{kind} eq 'schema', @$ast;
  die "Must provide only one schema definition.\n" if $e;
  my %name2type = %BUILTIN2TYPE;
  for (@type_nodes) {
    die "Type '$_->{name}' was defined more than once.\n"
      if $name2type{$_->{name}};
    require_module $kind2class->{$_->{kind}};
    $name2type{$_->{name}} = $kind2class->{$_->{kind}}->from_ast(\%name2type, $_);
  }
  if (!$schema_node) {
    # infer one
    $schema_node = +{
      map { $name2type{ucfirst $_} ? ($_ => ucfirst $_) : () } @TYPE_ATTRS
    };
  }
  die "Must provide schema definition with query type or a type named Query.\n"
    unless $schema_node->{query};
  my @directives = map GraphQL::Directive->from_ast(\%name2type, $_),
    grep $_->{kind} eq 'directive', @$ast;
  my $schema = $self->new(
    (map {
      $schema_node->{$_}
        ? ($_ => $name2type{$schema_node->{$_}}
          // die "Specified $_ type '$schema_node->{$_}' not found.\n")
        : ()
    } @TYPE_ATTRS),
    (@directives ? (directives => [ @GraphQL::Directive::SPECIFIED_DIRECTIVES, @directives ]) : ()),
    types => [ values %name2type ],
  );
  $schema->name2type; # walks all types, fields, args - finds undefined types
  $schema;
}

=head2 from_doc($doc)

Class method. Takes text that is a Schema Definition Language (SDL) (aka
Interface Definition Language) document and returns a schema object. Will
not be a complete schema since it will have only default resolvers.

As of v0.32, this accepts both old-style "meaningful comments" and
new-style string values, as field or type descriptions.

=cut

method from_doc(
  Str $doc,
) :ReturnType(InstanceOf[__PACKAGE__]) {
  $self->from_ast(parse($doc));
}

=head2 to_doc($doc)

Returns Schema Definition Language (SDL) document that describes this
schema object.

As of v0.32, this produces the new-style descriptions that are string
values, rather than old-style "meaningful comments".

=cut

has to_doc => (is => 'lazy', isa => Str);
my %directive2builtin = map { ($_=>1) } @GraphQL::Directive::SPECIFIED_DIRECTIVES;
sub _build_to_doc {
  my ($self) = @_;
  my $schema_doc;
  if (grep $self->$_->name ne ucfirst $_, grep $self->$_, @TYPE_ATTRS) {
    $schema_doc = join('', map "$_\n", "schema {",
      (map "  $_: @{[$self->$_->name]}", grep $self->$_, @TYPE_ATTRS),
    "}");
  }
  join "\n", grep defined,
    $schema_doc,
    (map $_->to_doc,
      sort { $a->name cmp $b->name }
      grep !$directive2builtin{$_},
      @{ $self->directives }),
    (map $self->name2type->{$_}->to_doc,
      grep !/^__/,
      grep !$BUILTIN2TYPE{$_},
      grep $CLASS2KIND{ref $self->name2type->{$_}},
      sort keys %{$self->name2type}),
    ;
}

=head2 name2directive

In this schema, returns a hash-ref mapping all directives' names to their
directive object.

=cut

has name2directive => (is => 'lazy', isa => Map[StrNameValid, InstanceOf['GraphQL::Directive']]);
method _build_name2directive() {
  +{ map { ($_->name => $_) } @{ $self->directives } };
}

=head1 FUNCTIONS

=head2 lookup_type($typedef, $name2type)

Turns given AST fragment into a type.

If the hash-ref's C<type> member is a string, will return a type of that name.

If an array-ref, first element must be either C<list> or C<non_null>,
second will be a recursive AST fragment, which will be passed into a
recursive call. The result will then have the modifier method (C<list>
or C<non_null>) called, and that will be returned.

=cut

fun lookup_type(
  HashRef $typedef,
  (Map[StrNameValid, InstanceOf['GraphQL::Type']]) $name2type,
) :ReturnType(InstanceOf['GraphQL::Type']) {
  my $type = $typedef->{type};
  die "Undefined type given\n" if !defined $type;
  return $name2type->{$type} // die "Unknown type '$type'.\n"
    if is_Str($type);
  my ($wrapper_type, $wrapped) = @$type;
  lookup_type($wrapped, $name2type)->$wrapper_type;
}

__PACKAGE__->meta->make_immutable();

1;
