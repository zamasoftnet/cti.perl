#!/usr/bin/perl
use strict;
use lib '../code';
use CTI::DriverManager;

# セッションの開始
my $uri = 'ctip://localhost:8099/';
my $session = CTI::DriverManager::get_session($uri,
	user => 'user', password => 'kappa');

# リソースの送信
my $rfp;
$session->start_resource(*STDOUT, 'test.css');
open($rfp, '<data/test.css');
while (<$rfp>) {print};
close($rfp);
$session->end_resource(*STDOUT);

# 文書の送信
$session->start_main(*STDOUT, '.');
open($rfp, '<data/test.html');
while (<$rfp>) {print};
close($rfp);
$session->end_main(*STDOUT);

# セッションの終了
$session->close();
