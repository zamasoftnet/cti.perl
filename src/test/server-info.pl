#!/usr/bin/perl
use strict;
use lib '../code';
use CTI::DriverManager;

# セッションの開始
my $uri = 'ctip://localhost:8099/';
my $session = CTI::DriverManager::get_session($uri,
	user => 'user', password => 'kappa');

print $session->get_server_info('http://www.cssj.jp/ns/ctip/version');

# セッションの終了
$session->close();
