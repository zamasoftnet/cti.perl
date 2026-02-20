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

# JPEG出力
$session->property('output.type', 'image/jpeg');

# ファイル出力
my $dir = 'out/output-dir';
mkdir($dir);
$session->set_output_as_directory($dir, '', '.jpg');

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
