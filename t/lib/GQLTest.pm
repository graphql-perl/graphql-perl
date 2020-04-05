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
    isa_ok $got, 'FakePromise' or return;
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
  # no API-compatible new method, as not going to hook into IO loop etc
  sub status {
    # status = undef/'fulfilled'/'rejected'
    my $self = shift;
    return $self->{status} unless @_;
    $self->{status} = shift;
  }
  sub values {
    my $self = shift;
    return @{$self->{values}} if $self->{values}; # has local values
    return $self->{parent}->get; # is chained
  }
  sub new {
    my ($class, %attrs) = @_;
    $class = ref($class) || $class; # object method too
    bless \%attrs, $class;
  }
  sub resolve { shift->new(status => 'fulfilled', values => [ @_ ]) }
  sub reject { shift->new(status => 'rejected', values => [ @_ ]) }
  sub all { shift->new(status => 'fulfilled', all => [ @_ ]) }
  sub then {
    my $self = shift;
    $self->new(parent => $self, handlers => +{ then => shift, catch => shift });
  }
  sub catch { shift->then(undef, @_) }
  sub _safe_call { my @r = eval { $_[0]->() }; ($@, @r); }
  sub _safe_call_setvalues {
    my ($self, $func) = @_;
    my ($e, @r) = _safe_call($func);
    $self->{values} = $e ? [ $e ] : \@r;
    $self->status($e ? 'rejected' : 'fulfilled');
    if (ref $self->{values}[0] eq __PACKAGE__) {
      # handler returned a promise, get value
      $e = $self->_safe_call_setvalues(sub { $self->{values}[0]->get });
    }
    $e;
  }
  sub _settle {
    my $self = shift;
    return if $self->{_settled};
    $self->{_settled} = 1;
    if ($self->{all}) {
      my @values;
      for (@{$self->{all}}) {
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
      $self->{values} = \@values;
    } elsif (my $h = $self->{handlers}) {
      # chained promise
      my $e = $self->_safe_call_setvalues(sub { $self->values });
      if (!$e and $h->{then}) {
        $e = $self->_safe_call_setvalues(sub { $h->{then}->($self->values) });
      }
      if ($e) {
        return if !$h->{catch};
        $e = $self->_safe_call_setvalues(sub { $h->{catch}->($self->values) });
      }
    }
  }
  sub get {
    my $self = shift;
    $self->_settle;
    my @values = $self->values;
    die @values if $self->status eq 'rejected';
    die "Tried to scalar-get but >1 value" if !wantarray and @values > 1;
    return $values[0] if !wantarray;
    @values;
  }
}

1;
