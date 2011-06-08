use Test::More;
use Test::Exception;

use_ok('Net::Kestrel');

SKIP: {
    skip "set TEST_NET_KESTREL_HOST to test Net::Kestrel on a live Kestrel instance", 1 unless $ENV{TEST_NET_KESTREL_HOST};
    my $host = $ENV{TEST_NET_KESTREL_HOST};
    my $port = $ENV{TEST_NET_KESTREL_PORT} || 2222;

    my $kes = Net::Kestrel->new(host => $host);
    $kes->put('ass', 'hole');

    cmp_ok('hole', 'eq', $kes->peek('ass'), 'peek');

    cmp_ok('hole', 'eq', $kes->get('ass'), 'get');
    ok($kes->confirm('ass', 1), 'confirm returned true');

    dies_ok { $kes->confirm('ass', 1) } 'confirm dies with no transaction open';
}

done_testing();