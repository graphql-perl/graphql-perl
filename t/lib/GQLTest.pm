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
  run_test nice_dump
);

sub import {
  my $target = caller;
  $target->export_to_level(1);
  $_->import::into(1) for @IMPORT;
}

sub run_test {
  my ($args, $expected) = @_;
  my $got = execute(@$args);
  cmp_deeply $got, $expected or diag nice_dump($got);
}

sub nice_dump {
  my ($got) = @_;
  local ($Data::Dumper::Sortkeys, $Data::Dumper::Indent, $Data::Dumper::Terse);
  $Data::Dumper::Sortkeys = $Data::Dumper::Indent = $Data::Dumper::Terse = 1;
  Dumper $got;
}

1;
