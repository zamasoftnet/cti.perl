=head1 NAME

CTI::DriverManager - CTI ドライバ

=head2 概要

ドキュメント変換サーバーに接続して、各種操作を行います。

=head1 SYNOPSIS

 use CTI::DriverManager;
 
 # セッションを取得する
 $uri = 'ctip://localhost:8099/';
 $session = CTI::DriverManager::get_session($uri,
	 user => 'user', password => 'kappa');
 $driver = CTI::DriverManager::get_driver($session);
 $session = $driver->get_session($uri,
	 user => 'user', password => 'kappa');

 # メッセージを表示する
 $session->set_message_func(sub {
	 my ($code, $message, @args) = @_;
	 printf "%X %s: %s\n", $code, $message, join(",", @args);
 });

 # 進行状況を表示する
 $session->set_progress_func(sub {
	 my ($length, $read) = @_;
	 print "[$read / $length]\n";
 });

 # バージョン情報を表示する
 print $session->get_server_info('http://www.cssj.jp/ns/ctip/version');

 # 出力先を設定する
 $session->set_output_as_stream(*STDOUT);
 $session->set_output_as_file("out.pdf");
 $session->set_output_as_directory("out", "", ".png");
 
 # プロパティを設定する
 $session->property('input.include', '**');
 
 # サーバー側で文書を取得して変換する
 $session->transcode('http://www.yahoo.co.jp/');

 # クライアント側のリソースを送る
 $session->start_resource(*STDOUT, 'test.css', mime_type => 'text/css');
 open(my $fp, '<test.css');
 while (<$fp>) {print};
 close($fp);
 $session->end_resource(*STDOUT);

 # サーバーの要求に応じてクライアント側のリソースを送る
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

 # クライアント側の文書を送って変換する
 $session->start_main(*STDOUT, 'main.html', mime_type => 'text/html');
 open(my $fp, '<main.html');
 while (<$fp>) {print};
 close($fp);
 $session->end_main(*STDOUT);
 
 # 初期状態に戻す
 $session->reset();
 
 # セッションを閉じる
 $session->close();

=head2 OPTIONS

get_session に渡すことが出来る、オプションは次のとおりです。

=over

=item user

	ユーザーID。

=item password

	パスワード。

=back

start_main, start_resource および、 set_resolver_func
のコールバック関数に渡されるコールバック関数に渡すことが出来る、オプションは次のとおりです。
全てのオプションは省略可能です。

=over

=item mime_type

	データのMIME-TYPE。
	
省略した場合は、自動判別されます。

=item encoding

	データのキャラクタ・エンコーディング。
	
省略した場合は、自動判別されます。
バイナリデータの場合は設定しても無視されます。

=item length

	データの予想されるバイト数。

基本的に省略して構いません。

設定しておくと、若干の処理速度の向上が期待できることと、
メインデータの場合は、set_progress_func
で設定した関数に元データの長さが渡されるようになります。

=item ignore_header

	1だと、データからCGIの出力等のヘッダ（先頭から空行までの間）を除去する。

これは既存のCGIプログラムの出力をキャプチャして変換する場合に有効です。
省略した場合は、全ての内容が入力データとして扱われます。

=back

=head2 作者

$Date: 2010-12-22 12:57:45 +0900 (2010年12月22日 (水)) $ MIYABE Tatsuhiko

=cut
package CTI::DriverManager;
require CTI::Driver;

require Exporter;
@ISA	= qw(Exporter);
@EXPORT_OK	= qw(create_driver_for);

use strict;
use Socket;

=head1 get_driver

C<get_driver URI>

指定されたURIに接続するためのドライバを返します。

=head2 パラメータ

=over

=item URI

	接続先アドレス

=back

=head2 戻り値

B<CTI::Driver>

=cut
sub get_driver ($) {
  my $uri = shift;
  return new CTI::Driver();
}

=head1 get_session

C<get_session URI [OPTIONS]>

指定されたURIに接続し、セッションを返します。

=head2 パラメータ

=over

=item URI

	接続先アドレス

=item OPTIONS

	接続オプション user => 'ユーザー名', password => 'パスワード'

=back

=head2 戻り値

B<CTI::Session>

=cut
sub get_session ($;%) {
  my ( $uri, %opts ) = @_;
  my $driver = get_driver($uri);
  return $driver->get_session($uri, %opts);
}

