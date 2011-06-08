package Net::Kestrel;
use Moose;

use IO::Socket;

# ABSTRACT: Kestrel Client for Perl

=head1 SYNOPSIS

    use Net::Kestrel;

    my $kes = Net::Kestrel->new; # defaults to host => 127.0.0.1, port => 2222
    $kes->put($queuename, $value);
    # ... later

    # take a peek, doesn't remove the item
    my $item = $kes->peek($queuename);

    # get the item out, beginning a transaction
    my $real_item = $kes->get($queuename);
    # ... do something with it
    
    # then confirm we finished it so kestrel can discard it
    $kes->confirm($queuename, 1); # since we got one item

=head1 DESCRIPTION

Net::Kestrel is a B<text protocol> client for L<https://github.com/robey/kestrel>.

=head1 NOTES

=head2 Protocol

Net::Kestrel speaks Kestrel's text protocol only at present.

=head2 Error Handling

Kestrel returns errors in the form of:

  -Error string

When any command returns a string like this, Net::Kestrel will die with that
message.  Therefore you should C<eval> any methods you care to deal with
errors for.

=attr debug

=cut

has 'debug' => (
    is => 'rw',
    isa => 'Bool',
    predicate => 'is_debug'
);

=attr host

The ip address of the Kestrel host you want to connect to.

=cut

has 'host' => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

=attr port

The port to connect to.  Defaults to 22133.

=cut

has 'port' => (
    is => 'ro',
    isa => 'Int',
    default => 2222
);

has _connection => (
    is => 'rw',
    isa => 'IO::Socket::INET',
    lazy_build => 1
);

sub _build__connection {
    my ($self) = @_;
    
    return IO::Socket::INET->new(
        PeerAddr => $self->host,
        PeerPort => $self->port,
        Proto => 'tcp'
    );
}

=method confirm ($queuename, $count)

Confirms $count items from the queue.

=cut

sub confirm {
    my ($self, $queue, $count) = @_;
    
    my $cmd = "confirm $queue $count\n";
    return $self->_write_and_read($cmd);
}

=method get ($queuename)

Gets an item from the queue.  Note that this implicitly begins a transaction
and the item must be C<confirm>ed or kestrel will give the item to another
client when you disconnect.

=cut

sub get {
    my ($self, $queue, $count) = @_;
    
    my $cmd = "get $queue\n";
    return $self->_write_and_read($cmd);
}

=method peek ($queuename)

Peeks into the specified queue and "peeks" at the next item.

=cut

sub peek {
    my ($self, $queue) = @_;
    
    my $cmd = "peek $queue\n";
    return $self->_write_and_read($cmd);
}

=method put ($queuename, $string)

Puts the provided payload into the specified queue.

=cut

sub put {
    my ($self, $queue, $thing) = @_;
    
    my $cmd = "put $queue:\n$thing\n\n";
    $self->_write_and_read($cmd);
}

sub _write_and_read {
    my ($self, $cmd) = @_;

    my $sock = $self->_connection;

    print STDERR "SENDING: $cmd\n" if $self->is_debug;
    $sock->send($cmd);

    my $resp = <$sock>;
    print STDERR "RESPONSE: $resp\n" if $self->is_debug;

    if($resp =~ /^:(.*)\n$/) {
        # Strip out "item" delimiters
        $resp = $1;
    } elsif($resp =~ /^\+(\d+)\n$/) {
        # Success with a count
        $resp = $1;
    } elsif($resp =~ /^-(.*)\n$/) {
        # Crap, an error.  throw it
        die $1;
    }

    return $resp;
}

1;

__END__


=begin :postlude

=head1 CONTRIBUTORS

Me

=end :postlude
