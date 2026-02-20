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

$session->set_message_func(sub {
	my ($code, $message, @args) = @_;
	printf ("%x %s ", $code, $message);
	foreach(@args) {
		print "[$_]";
	}
	print "\n";
});

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
