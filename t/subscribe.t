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
  use_ok( 'GraphQL::PubSub' ) || print "Bail out!\n";
  use_ok( 'curry' ) || print "Bail out!\n";
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
  my ($pubsub, $schema, $document) = @_;
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
    importantEmail => sub {
      my $ai = fake_promise_iterator();
      $pubsub->subscribe('importantEmail', $ai->curry::publish);
      $ai;
    },
  };
  return (
    # subscription
    subscribe(
      $schema, $document, $data, (undef) x 4, fake_promise_code(),
    ),
    # sendImportantEmail
    sub {
      my ($newEmail) = @_;
      push @{$data->{inbox}{emails}}, $newEmail;
      return $pubsub->publish('importantEmail', {
        importantEmail => {
          email => $newEmail,
          inbox => $data->{inbox},
        },
      });
    },
  );
}

my %FIXTURES = (
  emailMessage => {
    from => 'yuzhi@graphql.org',
    subject => 'Alright',
    message => 'Tests are good',
    unread => 1,
  },
  emailMessage2 => {
    from => 'hyo@graphql.org',
    subject => 'Alright 2',
    message => 'Tests are good 2',
    unread => 1,
  },
  payloadAfterSend1 => {
    data => {
      importantEmail => {
        email => { from => 'yuzhi@graphql.org', subject => 'Alright' },
        inbox => { unread => 1, total => 2 },
      },
    },
  },
  payloadAfterSend2 => {
    data => {
      importantEmail => {
        email => { from => 'hyo@graphql.org', subject => 'Alright 2' },
        inbox => { unread => 2, total => 3 },
      },
    },
  },
  documentEmailSubject => '
    subscription {
      importantEmail {
        email {
          subject
        }
      }
    }
  ',
  payloadSubjectHello => {
    data => { importantEmail => { email => { subject => 'Hello' } } },
  },
);

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

subtest 'Subscription Publish Phase' => sub {
  subtest 'produces a payload for multiple subscribe in same subscription' => sub {
    my $pubsub = GraphQL::PubSub->new;
    my ($sub1, $sendImportantEmail) = createSubscription($pubsub);
    $sub1 = $sub1->get;
    my ($sub2) = createSubscription($pubsub);
    $sub2 = $sub2->get;
    my $payload1_p = $sub1->next_p;
    my $payload2_p = $sub2->next_p;
    $sendImportantEmail->($FIXTURES{emailMessage});
    promise_test($payload1_p, [$FIXTURES{payloadAfterSend1}], '');
    promise_test($payload2_p, [$FIXTURES{payloadAfterSend1}], '');
  };
  subtest 'produces a payload per subscription event' => sub {
    my $pubsub = GraphQL::PubSub->new;
    my ($subscription, $sendImportantEmail) = createSubscription($pubsub);
    $subscription = $subscription->get;
    my $payload_p = $subscription->next_p;
    $sendImportantEmail->($FIXTURES{emailMessage});
    promise_test($payload_p, [$FIXTURES{payloadAfterSend1}], '');
    $sendImportantEmail->($FIXTURES{emailMessage2});
    promise_test($subscription->next_p, [$FIXTURES{payloadAfterSend2}], '');
    # TODO implement disconnection that upstream can act on
  };
  subtest 'event order is correct for multiple publishes' => sub {
    my $pubsub = GraphQL::PubSub->new;
    my ($subscription, $sendImportantEmail) = createSubscription($pubsub);
    $subscription = $subscription->get;
    my $payload_p = $subscription->next_p;
    $sendImportantEmail->($FIXTURES{emailMessage});
    $sendImportantEmail->($FIXTURES{emailMessage2});
    # this is different from JS tests, which say the first payload should show unread 2, total 3 because they are pull-orientated (settle on lookup) not push (settle on resolve)
    promise_test($payload_p, [$FIXTURES{payloadAfterSend1}], '');
    promise_test($subscription->next_p, [$FIXTURES{payloadAfterSend2}], '');
  };
  subtest 'should handle error during execution of source event' => sub {
    my $erroringEmailSchema = emailSchemaWithResolvers(
      sub {
        my $ai = fake_promise_iterator();
        $ai->publish({ email => { subject => 'Hello' } });
        $ai->publish({ email => { subject => 'Goodbye' } });
        $ai->publish({ email => { subject => 'Bonjour' } });
        $ai;
      },
      sub {
        die "Never leave.\n" if $_[0]->{email}{subject} eq 'Goodbye';
        $_[0];
      },
    );
    my $subscription = subscribe(
      $erroringEmailSchema,
      $FIXTURES{documentEmailSubject},
      (undef) x 5,
      fake_promise_code(),
    );
    $subscription = $subscription->get;
    promise_test($subscription->next_p, [$FIXTURES{payloadSubjectHello}], '');
    promise_test($subscription->next_p, [
      {
        data => { importantEmail => undef },
        errors => [
          {
            message => "Never leave.\n",
            locations => [{ line => 8, column => 5 }],
            path => ['importantEmail'],
          },
        ],
      },
    ], '');
    promise_test($subscription->next_p, [
      { data => { importantEmail => { email => { subject => 'Bonjour' } } } },
    ], '');
  };
  subtest 'should pass through error thrown in source event stream' => sub {
    my $erroringEmailSchema = emailSchemaWithResolvers(
      sub {
        my $ai = fake_promise_iterator();
        $ai->publish({ email => { subject => 'Hello' } });
        $ai->error("test error\n");
        $ai;
      },
      sub { $_[0] },
    );
    my $subscription = subscribe(
      $erroringEmailSchema,
      $FIXTURES{documentEmailSubject},
      (undef) x 5,
      fake_promise_code(),
    );
    $subscription = $subscription->get;
    promise_test($subscription->next_p, [$FIXTURES{payloadSubjectHello}], '');
    promise_test($subscription->next_p, [], "test error\n");
  };
  subtest 'should resolve GraphQL error from source event stream' => sub {
    my $erroringEmailSchema = emailSchemaWithResolvers(
      sub {
        my $ai = fake_promise_iterator();
        $ai->publish({ email => { subject => 'Hello' } });
        $ai->error(GraphQL::Error->coerce('test error'));
        $ai->close_tap;
        $ai;
      },
      sub { $_[0] },
    );
    my $subscription = subscribe(
      $erroringEmailSchema,
      $FIXTURES{documentEmailSubject},
      (undef) x 5,
      fake_promise_code(),
    );
    $subscription = $subscription->get;
    promise_test($subscription->next_p, [$FIXTURES{payloadSubjectHello}], '');
    promise_test($subscription->next_p, [
      {
        errors => [
          {
            message => "test error",
          },
        ],
      },
    ], '');
    is $subscription->next_p, undef; # exhaustion
  };
};

done_testing;
