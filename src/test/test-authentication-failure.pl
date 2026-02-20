#!/usr/bin/perl
use strict;
use lib '../code';
use CTI::DriverManager;

# セッションの開始
my $uri = 'ctip://localhost:8099/';
my $session = CTI::DriverManager::get_session($uri,
	user => 'oppe', password => 'kepe');

# セッションの終了
$session->close();
