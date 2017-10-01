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
    'Test::Exception' => '0.42',
  },
  PREREQ_PM => {
    'Moo' => '0',
    'Type::Tiny' => '0',
    'Function::Parameters' => '2.001001',
    'Return::Type' => '0',
    'Pegex' => '0',
    'MooX::Thunking' => '0.07', # takes care of Thunk in isa
    'JSON::MaybeXS' => '0',
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES => 'GraphQL-*' },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    dynamic_config => 0,
    resources => {
      x_IRC => 'irc://irc.perl.org/#graphql-perl',
      repository => {
        type => 'git',
        url => 'git@github.com:graphql-perl/graphql-perl.git',
        web => 'https://github.com/graphql-perl/graphql-perl',
      },
      license => [ 'http://dev.perl.org/licenses/' ],
    },
    prereqs => {
      develop => {
        requires => {
          'Test::CheckManifest' => '0.9',
          'Test::Pod::Coverage' => '1.08',
          'Test::Pod' => '1.22',
        },
      },
      runtime => {
        suggests => {
          'Cpanel::JSON::XS' => '3.0237',
        },
      },
    },
  },
);

sub MY::postamble {
  <<EOF;
lib/GraphQL/Grammar.pm : graphql.pgx
\t\$(PERL) -Ilib -MGraphQL::Grammar=compile
EOF
}
