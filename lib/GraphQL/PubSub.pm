package GraphQL::PubSub;

use 5.014;
use strict;
use warnings;
use Moo;
use GraphQL::Debug qw(_debug);
use Types::TypeTiny -all;
use Types::Standard -all;
use GraphQL::Type::Library -all;
use GraphQL::MaybeTypeCheck;

use constant DEBUG => $ENV{GRAPHQL_DEBUG};

=head1 NAME

GraphQL::PubSub - publish/subscribe

=head1 SYNOPSIS

  use GraphQL::PubSub;
  my $pubsub = GraphQL::PubSub->new;
  $pubsub->subscribe('channel1', \&callback);
  $pubsub->publish('channel1', 1);
  $pubsub->unsubscribe('channel1', \&callback);

=head1 DESCRIPTION

Encapsulates the publish/subscribe logic needed by L<GraphQL::Subscription>.

=head1 METHODS

=head2 subscribe($channel, \&callback[, \&error_callback])

Registers the given callback on the given channel.

The optional second "error" callback is called as a method on the object
when an exception is thrown by the first callback. If not given, the
default is for the subscription to be cancelled with L</unsubscribe>. The
error callback will be called with values of the channel, the original
callback (to enable unsubscribing), the exception thrown, then the values
passed to the original callback. Any exceptions will be ignored.

=cut

has _subscriptions => (is => 'ro', isa => HashRef, default => sub { {} });

method _default_error_callback(Str $channel, CodeLike $callback, Any $exception, @values) {
  eval { $self->unsubscribe($channel, $callback) };
}

method subscribe(Str $channel, CodeLike $callback, Maybe[CodeLike] $error_callback = undef) {
  $self->_subscriptions->{$channel}{$callback} = [
    $callback,
    $error_callback || \&_default_error_callback,
  ];
}

=head2 unsubscribe($channel, \&callback)

Removes the given callback from the given channel.

=cut

method unsubscribe(Str $channel, CodeLike $callback) {
  delete $self->_subscriptions->{$channel}{$callback};
}

=head2 publish($channel, @values)

Calls each callback registered on the given channel, with the given values.

=cut

method publish(Str $channel, @values) {
  for my $cb (values %{ $self->_subscriptions->{$channel} }) {
    my ($normal, $error) = @$cb;
    eval { $normal->(@values) };
    eval { $self->$error($channel, $normal, $@, @values) } if $@;
  }
}

__PACKAGE__->meta->make_immutable();

1;
