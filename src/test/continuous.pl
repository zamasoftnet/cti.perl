#!/usr/bin/perl
=head1 NAME

クライアント側リソース変換サンプル

=head2 概要

test.css,test.htmlを変換します。

=cut
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

$session->set_continuous(1);

# 文書の送信
$session->start_main(*STDOUT, '.');
open($rfp, '<data/test.html');
while (<$rfp>) {print};
close($rfp);
$session->end_main(*STDOUT);

# 文書の送信
$session->start_main(*STDOUT, '.');
open($rfp, '<data/test.html');
while (<$rfp>) {print};
close($rfp);
$session->end_main(*STDOUT);

$session->join();

# セッションの終了
$session->close();
