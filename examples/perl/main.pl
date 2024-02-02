#!/usr/bin/env perl
use 5.012;

use Data::MessagePack;
use Data::Dumper;
use ZMQ::FFI qw(ZMQ_REQ ZMQ_REP);

my $mpx = Data::MessagePack->new();
$mpx->utf8(1);

my $ctx = ZMQ::FFI->new();
my $skt = $ctx->socket(ZMQ_REQ);


# Connect to the StockMQ server
$skt->connect("tcp://10.211.55.3:8004");

# Send Request
$skt->send($mpx->pack(["getParamEx2", "TQBR", "SBER", "LAST"]));

# Receive Response
my $status = $skt->recv;
my $result = $skt->recv;

my $price = $mpx->unpack($result);

# Print (as below)
#   Status OK
#   param_type 1
#   result 1
#   param_image 276.64
#   param_value 276.640000
say "Status $status";
say "$_ $$price{$_}" for (keys %$price);