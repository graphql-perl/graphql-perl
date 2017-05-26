use 5.014;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'GraphQL',
  AUTHOR           => q{Ed J <etj@cpan.org>},
  VERSION_FROM     => 'lib/GraphQL.pm',
  ABSTRACT_FROM    => 'lib/GraphQL.pm',
  LICENSE          => 'artistic_2',
  MIN_PERL_VERSION => '5.014',
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '0',
  },
  TEST_REQUIRES => {
    'Test::More' => '0.88', # done_testing
  },
  PREREQ_PM => {
    'Moo' => '0',
    'Type::Tiny' => '0',
    'Function::Parameters' => '0',
    'Return::Type' => '0',
    'Pegex' => '0',
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES => 'GraphQL-*' },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'git@github.com:mohawk2/graphql-perl.git',
        web => 'https://github.com/mohawk2/graphql-perl',
      },
    },
    prereqs => {
      develop => {
        requires => {
          'Test::CheckManifest' => '0.9',
          'Test::Pod::Coverage' => '1.08',
          'Test::Pod' => '1.22',
        },
      },
    },
  },
);
