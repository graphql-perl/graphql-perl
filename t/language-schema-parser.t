#!perl
use 5.014;
use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
  use_ok( 'GraphQL::Parser' ) || print "Bail out!\n";
}

lives_ok { do_parse('type Hello { world: String }') } 'simple schema';
lives_ok { do_parse('extend type Hello { world: String }') } 'simple extend';
lives_ok { do_parse('type Hello { world: String! }') } 'non-null';
lives_ok { do_parse('type Hello implements World { }') } 'implements';
lives_ok { do_parse('type Hello implements Wo, rld { }') } 'implements multi';
lives_ok { do_parse('enum Hello { WORLD }') } 'single enum';
lives_ok { do_parse('enum Hello { WO, RLD }') } 'multi enum';
lives_ok { do_parse('interface Hello { world: String }') } 'simple interface';
lives_ok { do_parse('type Hello { world(flag: Boolean): String }') } 'type with arg';
lives_ok { do_parse('type Hello { world(flag: Boolean = true): String }') } 'type with default arg';
lives_ok { do_parse('type Hello { world(things: [String]): String }') } 'type with list arg';
lives_ok { do_parse('type Hello { world(argOne: Boolean, argTwo: Int): String }') } 'type with two args';

sub do_parse {
  return GraphQL::Parser->parse($_[0]);
}

done_testing;
