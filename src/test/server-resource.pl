#!/usr/bin/perl
use strict;
use lib '../code';
use CTI::DriverManager;

# セッションの開始
my $uri = 'ctip://localhost:8099/';
my $session = CTI::DriverManager::get_session($uri,
	user => 'user', password => 'kappa');

# ファイル出力
mkdir('out');
$session->set_output_as_file('out/server-resource.pdf');

# リソースのアクセス許可
$session->property('input.include', 'http://copper-pdf.com/**');
	
# 文書の送信
$session->transcode('http://copper-pdf.com/');

# セッションの終了
$session->close();
