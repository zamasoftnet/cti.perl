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
$session->set_output_as_file('out/resolver.pdf');

#リソースの送信
$session->set_resolver_func(sub {
	my ($uri, $open) = @_;
	if (-e $uri) {
	  my $fp = $open->();
	  open(my $rfp, "<$uri");
	  while (<$rfp>) {print $fp $_};
	  close($rfp);
	}
	return undef;
});
	
#文書の送信
$session->start_main(*STDOUT, 'data/test.html');
open(my $fp, '<data/test.html');
while (<$fp>) {print};
close($fp);
$session->end_main(*STDOUT);

#セッションの終了
$session->close();