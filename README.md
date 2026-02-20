# CTI Driver for Perl

Copper PDF 文書変換サーバーに接続するためのPerlドライバです。

使用方法は付属のAPIドキュメント、サンプルプログラムまたは以下のオンラインマニュアルを参照してください。

- オンラインマニュアル: http://dl.cssj.jp/docs/copper/3.0/html/3421_ctip2_perl.html

**バージョン:** 2.1.3

## 動作要件

- Perl 5.6.1 以降
- File::Temp モジュール
- IO::Socket::SSL （SSL接続をする場合）

## インストール

`src/code/CTI/` ディレクトリをプロジェクトにコピーし、Perlの `@INC` にパスを追加してください。

```perl
use lib '/path/to/code';
use CTI::DriverManager;
```

## 基本的な使い方

以下は、クライアント側のHTMLとCSSを送信してPDFに変換する基本的な例です。

```perl
use strict;
use lib 'src/code';
use CTI::DriverManager;

# セッションの開始
my $uri = 'ctip://localhost:8099/';
my $session = CTI::DriverManager::get_session($uri,
    user => 'user', password => 'kappa');

# ファイル出力
$session->set_output_as_file('output.pdf');

# リソース（CSS）の送信
my $rfp;
$session->start_resource(*STDOUT, 'test.css', mime_type => 'text/css');
open($rfp, '<test.css');
while (<$rfp>) { print };
close($rfp);
$session->end_resource(*STDOUT);

# 本体（HTML）の送信と変換
$session->start_main(*STDOUT, 'main.html', mime_type => 'text/html');
open($rfp, '<main.html');
while (<$rfp>) { print };
close($rfp);
$session->end_main(*STDOUT);

# セッションの終了
$session->close();
```

## API概要

`CTI::Session` の主要メソッド一覧です。

| メソッド | 説明 |
|---|---|
| `set_output_as_file(FILENAME)` | 変換結果の出力先ファイル名を指定する |
| `set_output_as_handle(HANDLE)` | 変換結果の出力先ファイルハンドルを指定する |
| `set_output_as_directory(DIR, PREFIX, SUFFIX)` | 変換結果の出力先ディレクトリ名を指定する |
| `set_message_func(FUNC)` | メッセージ受信のためのコールバック関数を設定する |
| `set_progress_func(FUNC)` | 進行状況受信のためのコールバック関数を設定する |
| `set_resolver_func(FUNC)` | リソース解決のためのコールバック関数を設定する |
| `property(NAME, VALUE)` | プロパティを設定する |
| `transcode(URI)` | サーバー側文書を変換する |
| `start_main(HANDLE, URI, OPTIONS)` | クライアント側の本体の送信を開始する |
| `end_main(HANDLE)` | 本体の送信を終了する |
| `start_resource(HANDLE, URI, OPTIONS)` | クライアント側リソースの送信を開始する |
| `end_resource(HANDLE)` | リソースの送信を終了する |
| `set_continuous(MODE)` | 複数の結果を結合するモードを切り替える |
| `join()` | 結果を結合する |
| `reset()` | 全ての状態をリセットする |
| `abort(MODE)` | 変換処理の中断を要求する |
| `close()` | セッションを閉じる |
| `get_server_info(URI)` | サーバー情報を返す |

詳細なAPIドキュメントは、各モジュールのPODドキュメントを参照してください。

## テストの実行方法

テストスクリプトは `src/test/` ディレクトリにあります。

テストを実行するには、まず接続先のCopper PDFサーバーが起動している必要があります。各テストはデフォルトで `ctip://localhost:8099/` に接続します。

```bash
prove t/driver.t
```

Ant からテストを実行する場合は、`cti.perl` 配下で以下を実行してください。

```bash
ant test
```

## ドキュメント生成方法

APIドキュメントはPOD（Plain Old Documentation）形式で各モジュールに記述されています。`ant pod` ターゲットを実行すると、`pod2html` を使用してHTMLドキュメントが `build/perl/apidoc/` に生成されます。

```bash
ant pod
```

生成されるドキュメントは以下のとおりです。

- `CTI/DriverManager.html`
- `CTI/Driver.html`
- `CTI/Session.html`
- `CTI/Builder/FileBuilder.html`
- `CTI/Builder/StreamBuilder.html`
- `CTI/Builder/NullBuilder.html`
- `CTI/Results/SingleResult.html`
- `CTI/Results/DirectoryResults.html`

## ライセンス

Copyright (c) 2011-2013 Zamasoft.

Apache License Version 2.0に基づいてライセンスされます。
あなたがこのファイルを使用するためには、本ライセンスに従わなければなりません。
本ライセンスのコピーは下記の場所から入手できます。

http://www.apache.org/licenses/LICENSE-2.0

適用される法律または書面での同意によって命じられない限り、
本ライセンスに基づいて頒布されるソフトウェアは、明示黙示を問わず、
いかなる保証も条件もなしに「現状のまま」頒布されます。
本ライセンスでの権利と制限を規定した文言については、本ライセンスを参照してください。

## 変更履歴

### v2.1.3 (2013/04/23)

- RPMが正常な場所にインストールされない不具合を修正。

### v2.1.2 (2012/04/10)

- 画像の出力時にContent-Lengthヘッダが不適切に出力されるため、画像出力時はContent-Lengthを自動で出力しないように修正。

### v2.1.1 (2011/03/16)

- .rpm, .deb パッケージをリリース。
- 大きな数値の扱い中に警告が出る問題を修正。

### v2.1.0 (2011/03/03)

- Copper PDF 3 以降からサポートする、複数の文書から1つのPDFを生成する機能に対応。
- TLS通信に対応。

### v2.0.0 (2010/01/11)

- 初回リリース。
