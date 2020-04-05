use lib 't/lib';
use strict;
use warnings;
use GQLTest;

my $JSON = JSON::MaybeXS->new->allow_nonref->canonical;

BEGIN {
  use_ok( 'GraphQL::Schema' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Subscription', qw(subscribe) ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Object' ) || print "Bail out!\n";
  use_ok( 'GraphQL::Type::Scalar', qw($String $Boolean $Int) ) || print "Bail out!\n";
  use_ok( 'GraphQL::Language::Parser', qw(parse) ) || print "Bail out!\n";
}

my $EmailType = GraphQL::Type::Object->new(
  name => 'Email',
  fields => {
    from => { type => $String },
    subject => { type => $String },
    message => { type => $String },
    unread => { type => $Boolean },
  },
);

my $InboxType = GraphQL::Type::Object->new(
  name => 'Inbox',
  fields => {
    total => {
      type => $Int,
      resolve => sub { scalar @{$_[0]->{emails}} },
    },
    unread => {
      type => $Int,
      resolve => sub { grep $_->{unread}, @{$_[0]->{emails}} },
    },
    emails => { type => $EmailType->list },
  },
);

my $QueryType = GraphQL::Type::Object->new(
  name => 'Query',
  fields => {
    inbox => { type => $InboxType },
  },
);

my $EmailEventType = GraphQL::Type::Object->new(
  name => 'EmailEvent',
  fields => {
    inbox => { type => $InboxType },
    email => { type => $EmailType },
  },
);

my $emailSchema = emailSchemaWithResolvers();

sub emailSchemaWithResolvers {
  my ($subscribeFn, $resolveFn) = @_;
  GraphQL::Schema->new(
    query => $QueryType,
    subscription => GraphQL::Type::Object->new(
      name => 'Subscription',
      fields => {
        importantEmail => {
          type => $EmailEventType,
          $resolveFn ? (resolve => $resolveFn) : (),
          $subscribeFn ? (subscribe => $subscribeFn) : (),
          args => {
            priority => { type => $Int },
          },
        },
      }
    ),
  );
}

my $defaultSubscriptionAST = parse('
  subscription ($priority: Int = 0) {
    importantEmail(priority: $priority) {
      email {
        from
        subject
      }
      inbox {
        unread
        total
      }
    }
  }
');

sub createSubscription {
  my (undef, $schema, $document) = @_;
  $schema ||= $emailSchema;
  $document ||= $defaultSubscriptionAST;
  my $data = {
    inbox => {
      emails => [
        {
          from => 'joe@graphql.org',
          subject => 'Hello',
          message => 'Hello World',
          unread => 0,
        },
      ],
    },
  };
  return (
    # subscription
    subscribe(
      $schema, $document, $data, (undef) x 4, fake_promise_code(),
    ),
    # sendImportantEmail
    undef,
  );
}

subtest 'Subscription Initialization Phase' => sub {
  subtest 'accepts positional arguments' => sub {
    my $document = parse('
      subscription {
        importantEmail
      }
    ');
    my $emptyAsyncIterator = sub {
      my $ai = fake_promise_iterator();
      $ai->close_tap;
      $ai;
    };
    my $ai = subscribe($emailSchema, $document, {
      importantEmail => $emptyAsyncIterator,
    }, (undef) x 4, fake_promise_code());
    $ai = $ai->get; # get promised value
    my $next = $ai->next_p;
    is $next, undef; # exhaustion
  };
  subtest 'resolves to an error for unknown subscription field' => sub {
    my $document = parse('
      subscription {
        unknownField
      }
    ');
    my ($subscription) = createSubscription(undef, $emailSchema, $document);
    promise_test($subscription, [{
      errors => [
        {
          message => "The subscription field 'unknownField' is not defined\n",
        },
      ],
    }], '');
  };
  subtest 'resolves to an error if variables were wrong type' => sub {
    my $res = subscribe(
      $emailSchema, $defaultSubscriptionAST, (undef) x 2,
      { priority => 'meow' },
      (undef) x 2, fake_promise_code(),
    );
    promise_test($res, [{
      errors => [
        {
          message => qq{Variable '\$priority' got invalid value "meow".\nNot an Int.\n},
        },
      ],
    }], '');
  };
};

done_testing;
