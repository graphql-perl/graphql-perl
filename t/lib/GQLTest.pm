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
    resolve => sub { FakePromise->resolve(@_) },
    reject => sub { FakePromise->reject(@_) },
    all => sub { FakePromise->all(@_) },
  };
}

{
  package FakePromise;
  use Moo;
  has status => (is => 'rw'); # status = undef/'fulfilled'/'rejected'
  has _values => (is => 'rw');
  has parent => (is => 'ro');
  has handlers => (is => 'ro');
  has _all => (is => 'ro');
  sub values {
    my $self = shift;
    return @{$self->_values} if $self->_values;
    if ($self->_all) {
      my @values;
      for (@{$self->_all}) {
        if (ref $_ ne __PACKAGE__) {
          push @values, [ $_ ];
          next;
        }
        my ($e, @r) = _safe_call(sub { $_->get });
        if ($e) {
          $self->status('rejected');
          @values = ($e);
          last;
        }
        push @values, [ @r ];
      }
      $self->_values(\@values);
    } elsif (my $p = $self->parent) {
      # chained promise
      my $e = $self->_safe_call_setvalues(sub { $p->get });
    }
    if (my $h = $self->handlers) {
      my @values = @{$self->_values};
      my $e = $self->status eq 'rejected' ? $values[0] : '';
      if (!$e and $h->{then}) {
        $e = $self->_safe_call_setvalues(sub { $h->{then}->(@values) });
      }
      if ($e and $h->{catch}) {
        $e = $self->_safe_call_setvalues(sub { $h->{catch}->($e) });
      }
    }
    @{$self->_values};
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
  sub all { shift->new(status => 'fulfilled', _all => [ @_ ]) }
  sub then {
    my $self = shift;
    $self->new(parent => $self, handlers => +{ then => shift, catch => shift });
  }
  sub catch { shift->then(undef, @_) }
  sub _safe_call { my @r = eval { $_[0]->() }; ($@, @r); }
  sub _safe_call_setvalues {
    my ($self, $func) = @_;
    my ($e, @r) = _safe_call($func);
    $self->_values($e ? [ $e ] : \@r);
    $self->status($e ? 'rejected' : 'fulfilled');
    if (ref $self->_values->[0] eq __PACKAGE__) {
      # handler returned a promise, get value
      $e = $self->_safe_call_setvalues(sub { $self->_values->[0]->get });
    }
    $e;
  }
  sub settle {
    my $self = shift;
    die "Error: tried to settle an already-settled promise"
      if defined $self->status;
    my $status = shift;
    $self->status($status);
    $self->_values([ @_ ]);
  }
  sub get {
    my $self = shift;
    die "Error: tried to 'get' a non-settled orphan promise"
      if !defined $self->status and !$self->parent and !$self->_all;
    my @values = $self->values;
    die @values if $self->status eq 'rejected';
    die "Tried to scalar-get but >1 value" if !wantarray and @values > 1;
    return $values[0] if !wantarray;
    @values;
  }
}

1;
