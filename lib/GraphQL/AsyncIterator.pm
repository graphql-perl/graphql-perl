package GraphQL::AsyncIterator;

use 5.014;
use strict;
use warnings;
use Moo;
use GraphQL::Debug qw(_debug);
use Types::Standard -all;
use Types::TypeTiny -all;
use GraphQL::Type::Library -all;
use GraphQL::PubSub;
use Function::Parameters;
use Return::Type;
use curry;

use constant DEBUG => $ENV{GRAPHQL_DEBUG};

=head1 NAME

GraphQL::AsyncIterator - iterator objects that return promise to next result

=head1 SYNOPSIS

  use GraphQL::AsyncIterator;
  my $i = GraphQL::AsyncIterator->new(
    promise_code => $pc,
  );
  # also works when publish happens before next_p called
  my $promised_value = $i->next_p;
  $i->publish('hi'); # now $promised_value will be fulfilled

  $i->close_tap; # now next_p will return undef

=head1 DESCRIPTION

Encapsulates the asynchronous event-handling needed for the
publish/subscribe behaviour needed by L<GraphQL::Subscription>.

=head1 ATTRIBUTES

=head2 promise_code

A hash-ref matching L<GraphQL::Type::Library/PromiseCode>, which must
provide the C<new> key.

=cut

has promise_code => (is => 'ro', isa => PromiseCode);

=head1 METHODS

=head2 publish(@values)

Resolves the relevant promise with C<@values>.

=cut

has _values_queue => (is => 'ro', isa => ArrayRef, default => sub { [] });
has _next_promise => (is => 'rw', isa => Maybe[Promise]);
has pubsub => (is => 'lazy', builder => sub { GraphQL::PubSub->new });

method publish(@values) {
  $self->_emit('resolve', \@values);
}

method _promisify((Enum[qw(resolve reject)]) $method, $data) {
  return $data if is_Promise($data);
  $self->promise_code->{$method}->(@$data);
}

method _thenify(Maybe[CodeLike] $then, Maybe[CodeLike] $catch, (Enum[qw(resolve reject)]) $method, $data) {
  return $data unless $then or $catch;
  $self->_promisify($method, $data)->then($then, $catch);
}

method _emit((Enum[qw(resolve reject)]) $method, $data) {
  if ($self->_exhausted) {
    die "Tried to emit to closed-off AsyncIterator\n";
  }
  my $passon;
  if (my $next_promise = $self->_next_promise) {
    $next_promise->$method(ref $data eq 'ARRAY' ? @$data : $data);
    $passon = $next_promise;
    $self->_next_promise(undef);
  } else {
    $passon = $self->_thenify($self->_then, $self->_catch, $method, $data);
    push @{$self->_values_queue},
      { data => $passon, method => $method, processed => 1 };
  }
  $self->pubsub->publish(_emit => $method, $passon) if $self->{pubsub};
}

=head2 error(@values)

Rejects the relevant promise with C<@values>.

=cut

method error(@values) {
  $self->_emit('reject', \@values);
}

=head2 next_p

Returns either a L<GraphQL::Type::Library/Promise> of the next value,
or C<undef> when closed off. Do not call this if a previous promised next
value has not been settled, as a queue is not maintained.

=cut

method next_p() :ReturnType(Maybe[Promise]) {
  return undef if $self->_exhausted and !@{$self->_values_queue};
  my $np;
  my $value;
  if (@{$self->_values_queue}) {
    $value = shift @{$self->_values_queue};
    $np = $self->_promisify(@$value{qw(method data)});
  } else {
    $np = $self->_next_promise($self->promise_code->{new}->());
  }
  (!$value or ($value and !$value->{processed}))
    ? $self->_thenify($self->_then, $self->_catch, 'resolve', $np)
    : $np;
}

=head2 close_tap

Switch to being closed off. L</next_p> will return C<undef> as soon as
it runs out of L</publish>ed values. L</publish> will throw an exception.
B<NB> This will not cause the settling of any outstanding promise returned
by L</next_p>.

=cut

has _exhausted => (is => 'rw', isa => Bool, default => sub { 0 });

method close_tap() :ReturnType(Maybe[Promise]) {
  return if $self->_exhausted; # already done - no need to redo or propagate
  $self->_exhausted(1);
  $self->pubsub->publish(close_tap => ()) if $self->{pubsub};
}

=head2 map_then($then, $catch)

Returns a new object, child of the current one, whose promises will
have the supplied C<then> and C<catch> handlers attached to promises
returned by L</next_p>.

Values published to the parent object will get propagated to all children.
If L</close_tap> is called on an object, that will get propagated to
all parents and children - this allow a child iterator to be used to
communicate the parent iterator should no longer receive values.

If values have already been published into the current object but not
read, they will be present in the child, being immediately processed by
the handlers.

=cut

has _then => (is => 'ro', isa => Maybe[CodeLike]);
has _catch => (is => 'ro', isa => Maybe[CodeLike]);

method map_then(Maybe[CodeLike] $then, Maybe[CodeLike] $catch = undef) :ReturnType(InstanceOf[__PACKAGE__]) {
  my @vq = map +{
    method => 'resolve',
    data => $self->_thenify($then, $catch, @$_{qw(method data)}),
    processed => 1,
  }, @{$self->_values_queue};
  my $new = $self->new(
    $then ? (_then => $then) : (),
    $catch ? (_catch => $catch) : (),
    _values_queue => \@vq,
    promise_code => $self->promise_code,
    _next_promise => $self->_next_promise,
    _exhausted => $self->_exhausted,
  );
  $self->pubsub->subscribe(_emit => $new->curry::_emit);
  $self->pubsub->subscribe(close_tap => $new->curry::close_tap);
  $new->pubsub->subscribe(close_tap => $self->curry::close_tap);
  $new;
}

__PACKAGE__->meta->make_immutable();

1;
