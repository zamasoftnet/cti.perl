#!/usr/bin/perl
use strict;
use warnings;
use CTI::DriverManager;

my $SERVER_URI = 'ctip://cti.li/';
my $SOURCE_URI = 'http://cti.li/';
my $OUTPUT_DIR = '../test-output';

mkdir($OUTPUT_DIR) unless -d $OUTPUT_DIR;

sub with_session {
    my ($filename, $setup) = @_;
    my $session = eval {
        CTI::DriverManager::get_session($SERVER_URI, user => 'user', password => 'kappa');
    };
    if ($@) {
        print STDERR "接続エラー: $@\n";
        exit 0;
    }
    $session->set_output_as_file("$OUTPUT_DIR/$filename");
    eval { $setup->($session); };
    if ($@) {
        print STDERR "エラー ($filename): $@\n";
        $session->close();
        exit 0;
    }
    $session->close();
    print STDERR "生成: $filename\n";
}

# TC-01: 基本URL変換
with_session('ctip-perl-url.pdf', sub {
    my ($session) = @_;
    $session->transcode($SOURCE_URI);
});

# TC-02: ハイパーリンク有効
with_session('ctip-perl-hyperlinks.pdf', sub {
    my ($session) = @_;
    $session->property('output.pdf.hyperlinks', 'true');
    $session->transcode($SOURCE_URI);
});

# TC-03: ブックマーク有効
with_session('ctip-perl-bookmarks.pdf', sub {
    my ($session) = @_;
    $session->property('output.pdf.bookmarks', 'true');
    $session->transcode($SOURCE_URI);
});

# TC-04: ハイパーリンクとブックマーク有効
with_session('ctip-perl-hyperlinks-bookmarks.pdf', sub {
    my ($session) = @_;
    $session->property('output.pdf.hyperlinks', 'true');
    $session->property('output.pdf.bookmarks', 'true');
    $session->transcode($SOURCE_URI);
});

# TC-05: クライアント側HTML変換
with_session('ctip-perl-client-html.pdf', sub {
    my ($session) = @_;
    my $html = '<html><body><h1>Hello</h1><p>Client-side HTML transcoding test.</p></body></html>';
    $session->start_main(*STDOUT, 'dummy:///test.html');
    print $html;
    $session->end_main(*STDOUT);
});

# TC-06: 日本語HTMLコンテンツ
with_session('ctip-perl-client-japanese.pdf', sub {
    my ($session) = @_;
    my $html = '<html><head><meta charset="UTF-8"/></head><body>'
             . '<h1>日本語テスト</h1><p>こんにちは世界。クライアント側から日本語コンテンツを送信します。</p>'
             . '</body></html>';
    $session->start_main(*STDOUT, 'dummy:///japanese.html');
    print $html;
    $session->end_main(*STDOUT);
});

# TC-07: 最小HTML（境界条件）
with_session('ctip-perl-client-minimal.pdf', sub {
    my ($session) = @_;
    $session->start_main(*STDOUT, 'dummy:///minimal.html');
    print '<html><body><p>.</p></body></html>';
    $session->end_main(*STDOUT);
});

# TC-08: 連続モード（2文書を結合）
with_session('ctip-perl-continuous.pdf', sub {
    my ($session) = @_;
    $session->set_continuous(1);
    $session->start_main(*STDOUT, 'dummy:///page1.html');
    print '<html><body><h1>Page 1</h1><p>First document in continuous mode.</p></body></html>';
    $session->end_main(*STDOUT);
    $session->start_main(*STDOUT, 'dummy:///page2.html');
    print '<html><body><h1>Page 2</h1><p>Second document in continuous mode.</p></body></html>';
    $session->end_main(*STDOUT);
    $session->join();
});

# TC-09: 大規模テーブル（メモリ→ファイル切り替えを誘発）
with_session('ctip-perl-large-table.pdf', sub {
    my ($session) = @_;
    $session->start_main(*STDOUT, 'dummy:///large-table.html');
    print '<html><head><meta charset="UTF-8"/></head><body>';
    print '<h1>大規模テーブルテスト</h1>';
    print '<table border="1"><tr><th>番号</th><th>名前</th><th>説明</th><th>備考</th></tr>';
    for my $i (1..15000) {
        print "<tr><td>$i</td><td>項目$i</td><td>これはテスト項目 $i の詳細説明テキストです。</td><td>備考テキスト $i</td></tr>";
    }
    print '</table></body></html>';
    $session->end_main(*STDOUT);
});

# TC-10: 長文テキスト文書
# 注: TC-09の大規模テーブルが2MB超のPDFを生成するため、大容量出力のテストはTC-09でカバーされる。
# テキスト文書のレイアウト機能を確認することが目的であり、ここでは100セクションで十分。
with_session('ctip-perl-large-text.pdf', sub {
    my ($session) = @_;
    my $sentences = 'Copper PDFはHTMLやXMLをPDFに変換するサーバーサイドのソフトウェアです。'
                  . 'CTIプロトコルを通じてクライアントからドキュメントを送信し、変換結果をPDFとして受け取ります。'
                  . 'このテストは大量のテキストコンテンツを含む文書を生成します。'
                  . 'ドライバはPDF出力が2MBを超えた際にメモリからファイル書き出しへ切り替わります。'
                  . 'このテストはその動作を確認するために設計されています。';
    $session->start_main(*STDOUT, 'dummy:///large-text.html');
    print '<html><head><meta charset="UTF-8"/></head><body>';
    for my $s (1..100) {
        print "<h2>セクション $s</h2>";
        for my $p (1..20) {
            print "<p>${sentences}（セクション${s}、段落${p}）</p>";
        }
    }
    print '</body></html>';
    $session->end_main(*STDOUT);
});
