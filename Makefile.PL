use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'GraphQL',
    AUTHOR           => q{Ed J <etj@cpan.org>},
    VERSION_FROM     => 'lib/GraphQL.pm',
    ABSTRACT_FROM    => 'lib/GraphQL.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
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
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'GraphQL-*' },
);
