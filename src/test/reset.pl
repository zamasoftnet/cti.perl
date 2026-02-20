#!/usr/bin/perl
use strict;
use lib '../code';
use CTI::DriverManager;

# セッションの開始
my $uri = 'ctip://localhost:8099/';
my $session = CTI::DriverManager::get_session($uri,
	user => 'user', password => 'kappa');

# ファイル出力
my $dir = 'out';
mkdir($dir);
$session->set_output_as_file('out/reset-1.pdf');

# リソースの送信
$session->start_resource(*STDOUT, 'test.css');
my $rfp;
open($rfp, '<data/test.css');
while (<$rfp>) {print};
close($rfp);
$session->end_resource(*STDOUT);
	
# 文書の送信
$session->start_main(*STDOUT, 'test.html');
open($rfp, '<data/test.html');
while (<$rfp>) {print};
close($rfp);
$session->end_main(*STDOUT);

# 事前に送って変換
$session->set_output_as_file('out/reset-2.pdf');
$session->start_resource(*STDOUT, 'test.html');
open($rfp, '<data/test.html');
while (<$rfp>) {print};
close($rfp);
$session->end_resource(*STDOUT);
$session->transcode('test.html');

# 同じ文書を変換
$session->set_output_as_file('out/reset-3.pdf');
$session->transcode('test.html');

# リセットして変換
$session->reset();
$session->set_output_as_file('out/reset-4.pdf');
$session->transcode('test.html');

# 再度変換
$session->set_output_as_file('out/reset-5.pdf');
$session->start_main(*STDOUT, 'test.html');
open($rfp, '<data/test.html');
while (<$rfp>) {print};
close($rfp);
$session->end_main(*STDOUT);

# セッションの終了
$session->close();
