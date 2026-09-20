#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
use File::Path qw(make_path remove_tree);
use IO::Socket::INET;
use Test::More;
use File::Spec;

use lib "$FindBin::Bin/../src/code";
use CTI::DriverManager;

my $uri = $ENV{CTI_SERVER_URI} || 'ctip://cti.li/';
my $host = $ENV{CTI_TEST_HOST};
my $port = $ENV{CTI_TEST_PORT} || 8099;
my $user = $ENV{CTI_TEST_USER} || 'user';
my $password = $ENV{CTI_TEST_PASSWORD} || 'kappa';

# 接続試験マトリクスの共通契約(copperpdf4/docs/design/2026-09-20-cti-driver-tls-test-matrix-design.md §2):
# CTI_TLS_INSECURE=1 で証明書を検証しない(insecure => 1)、CTI_EXPECT_REJECT=1 で
# 「証明書の検証で拒否されること」だけを試験する
my $insecure = ($ENV{CTI_TLS_INSECURE} // '') eq '1';
my $expect_reject = ($ENV{CTI_EXPECT_REJECT} // '') eq '1';
die "CTI_TLS_INSECURE=1 と CTI_EXPECT_REJECT=1 は同時に指定できません
" if $insecure && $expect_reject;
if (!defined $host && $uri =~ m{^ctips?://([^:/]+):?([0-9]+)?/?$}) {
    $host = $1;
    $port = $2 if defined $2 && length($2) > 0;
}
$host ||= 'localhost';
$port = int($port);

my $socket = IO::Socket::INET->new(
    PeerHost => $host,
    PeerPort => $port,
    Proto    => 'tcp',
    Timeout  => 2,
);
if (!$socket) {
    # 到達不能は失敗(黙って skip_all にしない。2026-09-20、マトリクスの契約)
    BAIL_OUT("Copper PDFサーバー ($host:$port) に接続できません。");
}
close $socket;

if ($expect_reject) {
    # 拒否試験(tls-reject / tls-badname): 接続を起こし、証明書の検証エラーで拒否されることだけを確かめる。
    # ドライバは失敗を warn して undef を返す(2.1.5)ので、warn の文言を捕まえる
    my $reason = '';
    local $SIG{__WARN__} = sub { $reason .= $_[0] };
    my $session = CTI::DriverManager::get_session($uri, user => $user, password => $password);
    if ($session) {
        $session->close();
        fail('証明書の検証で拒否されなかった(接続できてしまった)');
    } else {
        print "CTI-MATRIX reject: $reason";
        like($reason, qr/certificate verify failed|hostname verification/i, '証明書の検証で拒否される');
    }
    done_testing();
    exit;
}

sub data_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'src', 'test', 'data', @_);
}

sub create_session {
    my %options = @_;
    return CTI::DriverManager::get_session(
        $uri,
        user      => ($options{user} // $user),
        password  => ($options{password} // $password),
        ($insecure ? (insecure => 1) : ())
    );
}

sub convert_html_with_resources {
    my ($session, $output_file, $with_css) = @_;
    $with_css = 1 unless defined $with_css;

    my $css = data_path('test.css');
    my $html = data_path('test.html');

    $session->set_output_as_file($output_file);

    if ($with_css && -f $css) {
        my $css_in;
        $session->start_resource(*STDOUT, 'test.css');
        open($css_in, '<', $css) or die "テストデータを開けません。: $css";
        binmode $css_in;
        while (my $chunk = <$css_in>) {
            print $chunk;
        }
        close $css_in;
        $session->end_resource(*STDOUT);
    }

    my $in;
    open($in, '<', $html) or die "テストデータを開けません。: $html";
    binmode $in;
    $session->start_main(*STDOUT, '.');
    while (my $chunk = <$in>) {
        print $chunk;
    }
    $session->end_main(*STDOUT);
    close $in;
}

my $out_dir = "$FindBin::Bin/out";
remove_tree($out_dir);
make_path($out_dir);

my $session = create_session();
ok(defined $session, 'セッションを作成できる');
$session->close();

$session = create_session();
my $info = $session->get_server_info('http://www.cssj.jp/ns/ctip/version');
ok(defined $info && length($info) > 0, 'サーバー情報を取得できる');
$session->close();

$session = create_session();
my $out_file = "$out_dir/perl-output.pdf";
convert_html_with_resources($session, $out_file);
$session->close();

ok(-f $out_file, '変換結果のPDFファイルが生成される');
open(my $out, '<', $out_file) or die "出力ファイルを開けません。";
my $header = '';
read($out, $header, 4);
close $out;
is($header, '%PDF', 'PDFヘッダが正しく出力される');

$session = create_session();
my $resolved = 0;
$session->set_resolver_func(sub {
    my ($uri, $open) = @_;
    if ($uri eq 'test.css') {
        my $res_out = $open->();
        open(my $css_in, '<', data_path('test.css')) or return;
        binmode $css_in;
        while (my $line = <$css_in>) {
            print $res_out $line;
        }
        close $css_in;
        close $res_out;
        $resolved = 1;
    }
});
$session->set_output_as_file("$out_dir/perl-resolver.pdf");
open(my $resolver_in, '<', data_path('test.html')) or die "テストデータを開けません。: " . data_path('test.html');
binmode $resolver_in;
$session->start_main(*STDOUT, '.');
while (my $chunk = <$resolver_in>) {
    print $chunk;
}
$session->end_main(*STDOUT);
close $resolver_in;
$session->close();
ok($resolved, 'resolver が呼ばれてリソースを解決できる');

$session = create_session();
$session->property('output.pdf.version', '1.5');
my $property_out = "$out_dir/perl-property.pdf";
convert_html_with_resources($session, $property_out);
$session->close();
ok(-f $property_out, 'プロパティ設定後の変換結果が生成される');
open(my $property_fp, '<', $property_out) or die "出力ファイルを開けません。";
my $property_header = '';
read($property_fp, $property_header, 4);
close $property_fp;
is($property_header, '%PDF', 'プロパティ設定PDF: ヘッダが正しい');

$session = create_session();
my $progress = 0;
my $last_read = 0;
$session->set_progress_func(sub {
    my ($length, $read) = @_;
    $progress++;
    $last_read = $read if defined $read;
});
$session->set_results(CTI::Results::SingleResult->new(CTI::Builder::NullBuilder->new()));
$session->property('input.include', 'https://www.w3.org/**');
$session->transcode('https://www.w3.org/TR/xslt-10/');
ok($progress > 0, '進行状況コールバックが呼ばれる');
ok($last_read > 0, '進行状況に読み取りサイズがある');
$session->close();

$session = create_session();
$session->property('output.type', 'image/jpeg');
my $output_dir_image = "$out_dir/perl-output-dir";
make_path($output_dir_image);
$session->set_output_as_directory($output_dir_image, '', '.jpg');
open(my $dir_in, '<', data_path('test.html')) or die "テストデータを開けません。: " . data_path('test.html');
binmode $dir_in;
$session->start_main(*STDOUT, '.');
while (my $chunk = <$dir_in>) {
    print $chunk;
}
$session->end_main(*STDOUT);
close $dir_in;
$session->close();
my @images = glob("$out_dir/perl-output-dir/*.jpg");
ok(scalar(@images) > 0, '出力ディレクトリに結果が生成される');

$session = create_session();
convert_html_with_resources($session, "$out_dir/perl-reset-1.pdf");
$session->reset();
convert_html_with_resources($session, "$out_dir/perl-reset-2.pdf");
$session->close();
ok(-f "$out_dir/perl-reset-1.pdf", 'リセット前の変換結果が生成される');
ok(-f "$out_dir/perl-reset-2.pdf", 'リセット後の変換結果が生成される');

$session = create_session(user => 'invalid', password => 'invalid');
ok(!defined $session, '認証失敗時にセッションを作成できない');

# ---- プロトコルの周辺機能(2026-09-20、接続試験マトリクスの拡張)。
# 主要機能の 8 項目に、メッセージ受信・中断・ストリーム出力・連続結合を足す。7 本のドライバで同じ 4 項目。

my $MISSING_CSS_HTML = '<html><head><link rel="stylesheet" href="missing.css"></head><body><p>message test</p></body></html>';

sub big_html {
    my ($paragraphs) = @_;
    my $filler = 'x' x 300;
    return '<html><body>' . join('', map { "<p>paragraph $_ $filler</p>" } 0 .. $paragraphs - 1) . '</body></html>';
}

sub transcode_string {
    my ($session, $html) = @_;
    $session->start_main(*STDOUT, '.', mime_type => 'text/html');
    print $html;
    $session->end_main(*STDOUT);
}

# StreamBuilder は syswrite で書くので、メモリ上のハンドル(open '>', \$buf)には書けない。実ファイルのハンドルを使い、
# 閉じた後に読み戻す(戻り値の 2 つ目は閉じてから中身を返すクロージャ)
my $handle_seq = 0;
sub memory_handle {
    my $path = "$out_dir/perl-handle-" . ++$handle_seq . ".bin";
    open(my $fh, '>', $path) or die $!;
    binmode $fh;
    return ($fh, $path);
}

sub slurp {
    my ($path) = @_;
    open(my $in, '<', $path) or return '';
    binmode $in;
    local $/;
    my $data = <$in>;
    close $in;
    return defined $data ? $data : '';
}

# メッセージ受信: 存在しないスタイルシートを参照する文書で、サーバーのエラーメッセージが関数に届く(引数にその名前が入る)
{
    my @messages;
    my ($fh, $buf) = memory_handle();
    $session = create_session();
    $session->set_message_func(sub { my ($code, $message, @args) = @_; push @messages, [$code, $message, [@args]]; });
    $session->set_output_as_handle($fh);
    transcode_string($session, $MISSING_CSS_HTML);
    $session->close();
    close $fh;
    is(substr(slurp($buf), 0, 4), '%PDF', 'メッセージ試験の変換結果が PDF');
    my @hits = grep { (grep { $_ eq 'missing.css' } @{$_->[2]}) || index($_->[1], 'missing.css') >= 0 } @messages;
    ok(scalar(@hits) > 0, 'missing.css についてのメッセージが届く') or diag(join(' | ', map { "$_->[0] $_->[1]" } @messages));
    ok(!grep({ !($_->[0] > 0) } @hits), 'メッセージコードが正の整数');
}

# 中断: 本文の送信中に abort を送ると変換が止まり(完全な出力が返らない)、reset 後に同じセッションで再変換できる。
# サーバーが中断をどのメッセージで報告するかは版で違うので見ない
{
    my $html = big_html(3000);
    $session = create_session();
    my ($full_fh, $full) = memory_handle();
    $session->set_output_as_handle($full_fh);
    transcode_string($session, $html);
    close $full_fh;
    is(substr(slurp($full), 0, 4), '%PDF', '中断試験の対照(完全な変換)が PDF');
    $session->reset();

    my ($aborted_fh, $aborted) = memory_handle();
    $session->set_output_as_handle($aborted_fh);
    my $half = int(length($html) / 2);
    {
        local $SIG{__WARN__} = sub { };   # 中断の報告(版により警告)は見ない
        $session->start_main(*STDOUT, '.', mime_type => 'text/html');
        print substr($html, 0, $half);
        $session->abort(1);
        print substr($html, $half);
        $session->end_main(*STDOUT);
    }
    close $aborted_fh;
    ok(length(slurp($aborted)) < length(slurp($full)), '中断すると完全な出力は返らない');
    $session->reset();

    my ($again_fh, $again) = memory_handle();
    $session->set_output_as_handle($again_fh);
    transcode_string($session, '<p>after abort</p>');
    $session->close();
    close $again_fh;
    is(substr(slurp($again), 0, 4), '%PDF', '中断後のセッションで再変換できる');
}

# ストリーム出力: set_output_as_handle で結果がハンドルに書かれる
{
    my ($fh, $buf) = memory_handle();
    $session = create_session();
    $session->set_output_as_handle($fh);
    open(my $css, '<', data_path('test.css')) or die $!;
    binmode $css;
    $session->start_resource(*STDOUT, 'test.css');
    while (my $chunk = <$css>) { print $chunk; }
    $session->end_resource(*STDOUT);
    close $css;
    open(my $in, '<', data_path('test.html')) or die $!;
    binmode $in;
    $session->start_main(*STDOUT, '.');
    while (my $chunk = <$in>) { print $chunk; }
    $session->end_main(*STDOUT);
    close $in;
    $session->close();
    close $fh;
    is(substr(slurp($buf), 0, 4), '%PDF', 'ハンドルへの出力が PDF');
    ok(length(slurp($buf)) > 100, 'ハンドルへの出力に中身がある');
}

# 連続結合: 連続モードで 2 文書を変換して join すると 1 つの PDF になる(1 文書より大きい)
{
    my ($single_fh, $single) = memory_handle();
    $session = create_session();
    $session->set_output_as_handle($single_fh);
    transcode_string($session, '<p>doc 0</p>');
    $session->close();
    close $single_fh;

    my ($joined_fh, $joined) = memory_handle();
    $session = create_session();
    $session->set_output_as_handle($joined_fh);
    $session->set_continuous(1);
    transcode_string($session, "<p>doc $_</p>") for 0 .. 1;
    $session->join();
    $session->close();
    close $joined_fh;
    is(substr(slurp($joined), 0, 4), '%PDF', '結合した出力が PDF');
    ok(length(slurp($joined)) > length(slurp($single)), '結合した出力が 1 文書より大きい');
}

done_testing();
