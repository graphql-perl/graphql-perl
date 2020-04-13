use strict;
use warnings;
use base 'Exporter';

my @IMPORT;
BEGIN {
@IMPORT = qw(
  strict
  warnings
  Test::More
  Test::Exception
  Test::Deep
  JSON::MaybeXS
);
do { eval "use $_; 1" or die $@ } for @IMPORT;
}

use Data::Dumper;

our @EXPORT = qw(
  run_test fake_promise_code promise_test
);

sub import {
  my $target = caller;
  $target->export_to_level(1);
  $_->import::into(1) for @IMPORT;
}

sub run_test {
  my ($args, $expected, $force_promise) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my @args = @$args;
  $args[7] ||= fake_promise_code() if !defined $force_promise or $force_promise;
  my $got = execute(@args);
  if (!defined $force_promise) {
    if (ref $got eq 'FakePromise') {
      $got = eval { $got->get };
      is $@, '' or diag(explain $@), return;
    }
  } elsif ($force_promise) {
    isa_ok $got, 'FakePromise' or diag(explain $got), return;
    $got = eval { $got->get };
    is $@, '' or diag(explain $@), return;
  } else {
    # specified did not want promise
    isnt ref($got), 'FakePromise' or return;
  }
  cmp_deeply $got, $expected or diag explain $got;
}

sub promise_test {
  my ($p, $fulfilled, $rejected) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my $got = [ eval { $p->get } ];
  is_deeply $got, $fulfilled or diag 'got unexpected result: ', explain $got;
  my $e = $@;
  is $e, $rejected or diag 'got unexpected error: ', explain $e;
}

sub fake_promise_code {
  +{
    resolve => FakePromise->curry::resolve,
    reject => FakePromise->curry::reject,
    all => FakePromise->curry::all,
    new => FakePromise->curry::new,
  };
}

sub fake_promise_iterator {
  require GraphQL::AsyncIterator;
  GraphQL::AsyncIterator->new(
    promise_code => fake_promise_code(),
  );
}

{
  package FakePromise;
  use Moo;
  use GraphQL::PubSub;
  use curry;
  has status => (is => 'rw'); # status = undef/'fulfilled'/'rejected'
  has _values => (is => 'rw');
  has parent => (is => 'ro');
  has handlers => (is => 'ro');
  has pubsub => (is => 'lazy', builder => sub { GraphQL::PubSub->new });
  sub BUILD {
    my ($self, $args) = @_;
    if (my $parent = $args->{parent}) {
      $self->_get_or_subscribe($parent, $self->curry::settle);
    }
  }
  sub _get_or_subscribe {
    my ($self, $promise, $func) = @_;
    if (defined(my $status = $promise->status)) {
      # parent settled, copy now
      $func->($status, @{$promise->_values});
    } else {
      $promise->pubsub->subscribe(settle => $func);
    }
  }
  sub resolve {
    my $self = shift;
    $self = $self->new if !ref $self;
    $self->settle('fulfilled', @_);
    $self;
  }
  sub reject {
    my $self = shift;
    $self = $self->new if !ref $self;
    $self->settle('rejected', @_);
    $self;
  }
  sub all {
    my $self = shift;
    die "all is a class method only" if ref $self;
    $self = $self->new;
    my ($i, @values) = (0);
    my $unsettled = grep ref($_) eq __PACKAGE__, @_;
    my @promise_deferral; # till after @values filled, avoid prematurely settle
    for my $v (@_) {
      if (ref(my $promise = $v) eq __PACKAGE__) {
        my $this_value_index = $i;
        push @values, undef;
        push @promise_deferral, [ $promise, sub {
          my ($status, @these_vals) = @_;
          if ($status eq 'rejected') {
            $self->settle($status, @these_vals);
          } elsif (!defined $self->status) {
            # if it IS defined, we already got rejected so it's over
            $values[$this_value_index] = \@these_vals;
            $unsettled--;
            if ($unsettled <= 0) {
              $self->settle('fulfilled', @values);
            }
          }
        } ];
      } else {
        push @values, [ $v ];
      }
      $i++;
    }
    $self->_get_or_subscribe(@$_) for @promise_deferral;
    $self;
  }
  sub then {
    my $self = shift;
    $self->new(parent => $self, handlers => +{ then => shift, catch => shift });
  }
  sub catch { shift->then(undef, @_) }
  sub _safe_call {
    my @r = eval { $_[0]->() };
    $@ ? ('rejected', $@) : ('fulfilled', @r);
  }
  sub _settled_with_promise {
    my ($self, $value) = @_;
    return 0 if ref($value) ne __PACKAGE__;
    $self->_get_or_subscribe($value, $self->curry::settle);
    1;
  }
  sub settle {
    my $self = shift;
    die "Error: tried to settle an already-settled promise"
      if defined $self->status;
    my ($status, @values) = @_;
    return if $self->_settled_with_promise($values[0]);
    if (my $h = delete $self->{handlers}) {
      # zap as no longer needed, might get rerun if was settled with promise
      if ($status eq 'fulfilled' and $h->{then}) {
        ($status, @values) = _safe_call(sub { $h->{then}->(@values) });
        return if $self->_settled_with_promise($values[0]);
      }
      if ($status eq 'rejected' and $h->{catch}) {
        ($status, @values) = _safe_call(sub { $h->{catch}->(@values) });
        return if $self->_settled_with_promise($values[0]);
      }
    }
    $self->status($status);
    $self->_values(\@values);
    $self->pubsub->publish(settle => $status, @values) if $self->{pubsub};
  }
  sub get {
    my $self = shift;
    die "Error: tried to 'get' a non-settled promise"
      if !defined $self->status;
    my @values = @{$self->_values};
    die @values if $self->status eq 'rejected';
    die "Tried to scalar-get but >1 value" if !wantarray and @values > 1;
    return $values[0] if !wantarray;
    @values;
  }
}

1;
