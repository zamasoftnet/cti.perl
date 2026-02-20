#!/usr/bin/perl
use strict;
use lib '../code';
use CTI::DriverManager;
use CTI::Results::SingleResult;
use CTI::Builder::NullBuilder;

# セッションの開始
my $uri = 'ctip://localhost:8099/';
my $session = CTI::DriverManager::get_session($uri,
	user => 'user', password => 'kappa');
	
# 出力しない
$session->set_results(CTI::Results::SingleResult->new(CTI::Builder::NullBuilder->new()));

$session->set_progress_func(sub {
	my ($length, $read) = @_;
	print "$read / $length\n";
});

#リソースのアクセス許可
$session->property('input.include', 'http://www.w3.org/**');
	
#文書の送信
$session->transcode('http://www.w3.org/TR/xslt');

#セッションの終了
$session->close();
