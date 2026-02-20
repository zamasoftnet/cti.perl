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

$session->set_output_as_handle(*STDOUT, 1);
$session->property('output.type', 'image/svg+xml');

# 文書の送信
$session->start_main(*STDOUT, '.');
print << "END_OF_HTML";
<html>
<head>
<title>Title</title>
</head>
<body>
TEXT
</body>
</html>
END_OF_HTML
$session->end_main(*STDOUT);

# セッションの終了
$session->close();
