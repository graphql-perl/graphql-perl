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
  run_test nice_dump fake_promise_code promise_test
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
      is $@, '' or diag(nice_dump($@)), return;
    }
  } elsif ($force_promise) {
    isa_ok $got, 'FakePromise' or return;
    $got = eval { $got->get };
    is $@, '' or diag(nice_dump($@)), return;
  } else {
    # specified did not want promise
    isnt ref($got), 'FakePromise' or return;
  }
  cmp_deeply $got, $expected or diag nice_dump($got);
}

sub nice_dump {
  my ($got) = @_;
  local ($Data::Dumper::Sortkeys, $Data::Dumper::Indent, $Data::Dumper::Terse);
  $Data::Dumper::Sortkeys = $Data::Dumper::Indent = $Data::Dumper::Terse = 1;
  Dumper $got;
}

sub promise_test {
  my ($p, $fulfilled, $rejected) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my $got = [ eval { $p->get } ];
  is_deeply $got, $fulfilled or diag 'got: ', nice_dump $got;
  my $e = $@;
  is $e, $rejected or diag 'got: ', nice_dump $e;
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
  sub steps {
    # hash-ref with then and/or catch
    my $self = shift;
    return $self->{steps} unless @_;
    die "steps is read-only\n";
  }
  sub values {
    my $self = shift;
    return @{$self->{values}} unless @_;
    $self->{values} = [ @_ ];
  }
  sub new {
    my ($class, %attrs) = @_;
    bless +{ %attrs, steps => [] }, $class;
  }
  sub resolve { shift->new(status => 'fulfilled', values => [ @_ ]) }
  sub reject { shift->new(status => 'rejected', values => [ @_ ]) }
  sub all { shift->new(status => 'fulfilled', all => [ @_ ]) }
  sub then {
    my $self = shift;
    push @{$self->steps}, +{ then => shift, catch => shift };
    $self;
  }
  sub catch { shift->then(undef, @_) }
  sub _safe_call { my @r = eval { $_[0]->() }; ($@, @r); }
  sub _onestep {
    die "_onestep not in array context" if !wantarray;
    my ($e, @r) = _safe_call($_[0]);
    return ('catch', $e) if $e;
    return ('then', @r) if ref $r[0] ne __PACKAGE__;
    # real package would deal with still-pending
    @_ = sub { $r[0]->get }; goto &_onestep; # tail recursion
  }
  sub _mapsteps {
    my ($self, $key, @values) = @_;
    for (@{$self->steps}) {
      next if !$_->{$key};
      ($key, @values) = _onestep(sub { $_->{$key}->(@values) });
    }
    $self->status($key eq 'then' ? 'fulfilled' : 'rejected');
    @values;
  }
  sub _finalise {
    my $self = shift;
    my @values;
    if ($self->{all}) {
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
    } else {
      @values = $self->values;
    }
    if ($self->status eq 'fulfilled') {
      @values = $self->_mapsteps('then', @values);
    } elsif ($self->status eq 'rejected') {
      @values = $self->_mapsteps('catch', @values);
    }
    $self->{_settled} = 1;
    $self->values(@values);
  }
  sub get {
    my $self = shift;
    $self->_finalise if !$self->{_settled};
    my @values = $self->values; # must be settled ie fulfilled or rejected
    die @values if $self->status eq 'rejected';
    die "Tried to scalar-get but >1 value" if !wantarray and @values > 1;
    return $values[0] if !wantarray;
    @values;
  }
}

1;
