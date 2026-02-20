=head1 NAME

CTI::CTIP2::CTIP - CTIPプロトコルハンドラ

=head2 概要

CTIPの低レベルの部分を扱います。

通常、プログラマがこのパッケージを直接使う必要はありません。

=head2 作者

$Date: 2011-01-20 20:01:03 +0900 (2011年01月20日 (木)) $ MIYABE Tatsuhiko

=cut
package CTI::CTIP2::CTIP;
use CTI::Helpers;

require Exporter;
@ISA	= qw(Exporter);

use strict;
use Symbol qw(qualify_to_ref);

sub REQ_PROPERTY { return 0x01; }

sub REQ_START_MAIN { return 0x02; }

sub REQ_SERVER_MAIN { return 0x03; }

sub REQ_CLIENT_RESOURCE { return 0x04; }

sub REQ_CONTINUOUS { return 0x05; }

sub REQ_DATA { return 0x11; }

sub REQ_START_RESOURCE { return 0x21; }

sub REQ_MISSING_RESOURCE { return 0x22; }

sub REQ_EOF { return 0x31; }

sub REQ_ABORT { return 0x32; }

sub REQ_JOIN { return 0x33; }

sub REQ_RESET { return 0x41; }

sub REQ_CLOSE { return 0x42; }

sub REQ_SERVER_INFO { return 0x51; }


sub RES_START_DATA { return 0x01; }

sub RES_BLOCK_DATA { return 0x11; }

sub RES_ADD_BLOCK { return 0x12; }

sub RES_INSERT_BLOCK { return 0x13; }

sub RES_MESSAGE { return 0x14; }

sub RES_MAIN_LENGTH { return 0x15; }

sub RES_MAIN_READ { return 0x16; }

sub RES_DATA { return 0x17; }

sub RES_CLOSE_BLOCK { return 0x18; }

sub RES_RESOURCE_REQUEST { return 0x21; }

sub RES_EOF { return 0x31; }

sub RES_ABORT { return 0x32; }

sub RES_NEXT { return 0x33; }

=head1 connect

C<connect IOHANDLE ENCODING>

セッションを開始します。

=head2 引数

=over

=item IOHANDLE 入出力ストリーム(通常はソケット)

=item ENCODING 通信に用いるエンコーディング

=back

=head2 戻り値

B<成功なら1,失敗ならundef>

=cut
sub connect (*$) {
  my $fp = shift;
  my $encoding = shift;
  my $str = "CTIP/2.0 $encoding\n";
  $fp = Symbol::qualify_to_ref($fp, caller());
  
  defined(CTI::Helpers::write($fp, $str)) or return undef;
  return 1;
}

=head1 req_server_info

C<req_server_info IOHANDLE URI>

サーバー情報を要求します。

=head2 引数

=over

=item IOHANDLE 入出力ストリーム(通常はソケット)

=item URI 情報のURI。

=back

=head2 戻り値

B<成功なら1,失敗ならundef>

=cut
sub req_server_info (*$) {
  my ($fp, $uri) = @_;
  $fp = Symbol::qualify_to_ref($fp, caller);
  my $len = length($uri);

  my $payload = 1 + 2 + $len;
  defined(CTI::Helpers::write_int($fp, $payload)) or return undef;
  defined(CTI::Helpers::write_byte($fp, CTI::CTIP2::CTIP::REQ_SERVER_INFO)) or return undef;
  defined(CTI::Helpers::write_bytes($fp, $uri)) or return undef;
  return 1;
}

=head1 req_client_resource

C<req_client_resource IOHANDLE MODE>

サーバーからクライアントのリソースを要求するモードを切り替えます。

=head2 引数

=over

=item IOHANDLE 入出力ストリーム(通常はソケット)

=item MODE リソースの解決モード。

=back

=head2 戻り値

B<成功なら1,失敗ならundef>

=cut
sub req_client_resource (*$) {
  my ($fp, $mode) = @_;
  $fp = Symbol::qualify_to_ref($fp, caller);

  my $payload = 2;
  defined(CTI::Helpers::write_int($fp, $payload)) or return undef;
  defined(CTI::Helpers::write_byte($fp, CTI::CTIP2::CTIP::REQ_CLIENT_RESOURCE)) or return undef;
  defined(CTI::Helpers::write_byte($fp, $mode)) or return undef;
  return 1;
}

=head1 req_continuous

C<req_continuous IOHANDLE MODE>

結果を結合するモードを切り替えます。

=head2 引数

=over

=item IOHANDLE 入出力ストリーム(通常はソケット)

=item 結果を結合するモード。

=back

=head2 戻り値

B<成功なら1,失敗ならundef>

=cut
sub req_continuous (*$) {
  my ($fp, $mode) = @_;
  $fp = Symbol::qualify_to_ref($fp, caller);

  my $payload = 2;
  defined(CTI::Helpers::write_int($fp, $payload)) or return undef;
  defined(CTI::Helpers::write_byte($fp, CTI::CTIP2::CTIP::REQ_CONTINUOUS)) or return undef;
  defined(CTI::Helpers::write_byte($fp, $mode)) or return undef;
  return 1;
}

=head1 req_missing_resource

C<req_missing_resource IOHANDLE URI>

リソースの不存在を通知します。

=head2 引数

=over

=item IOHANDLE 入出力ストリーム(通常はソケット)

=item URI リソースのURI

=back

=head2 戻り値

B<成功なら1,失敗ならundef>

=cut
sub req_missing_resource (*$) {
  my ($fp, $uri) = @_;
  $fp = Symbol::qualify_to_ref($fp, caller);

  my $payload = 1 + 2 + length($uri);
  defined(CTI::Helpers::write_int($fp, $payload)) or return undef;
  defined(CTI::Helpers::write_byte($fp, CTI::CTIP2::CTIP::REQ_MISSING_RESOURCE)) or return undef;
  defined(CTI::Helpers::write_bytes($fp, $uri)) or return undef;
  return 1;
}

=head1 req_reset

C<req_reset IOHANDLE>

状態のリセットを要求します。

=head2 引数

=over

=item IOHANDLE 入出力ストリーム(通常はソケット)

=back

=head2 戻り値

B<成功なら1,失敗ならundef>

=cut
sub req_reset (*) {
  my ($fp) = @_;
  $fp = Symbol::qualify_to_ref($fp, caller());

  my $payload = 1;
  defined(CTI::Helpers::write_int($fp, $payload)) or return undef;
  defined(CTI::Helpers::write_byte($fp, CTI::CTIP2::CTIP::REQ_RESET)) or return undef;
  return 1;
}

=head1 req_abort

C<req_abort IOHANDLE MODE>

変換処理の中断を要求します。

=head2 引数

=over

=item IOHANDLE 入出力ストリーム(通常はソケット)

=item MODE 中断モード

=back

=head2 戻り値

B<成功なら1,失敗ならundef>

=cut
sub req_abort (*$) {
  my ($fp, $mode) = @_;
  $fp = Symbol::qualify_to_ref($fp, caller());

  my $payload = 2;
  defined(CTI::Helpers::write_int($fp, $payload)) or return undef;
  defined(CTI::Helpers::write_byte($fp, CTI::CTIP2::CTIP::REQ_ABORT)) or return undef;
  defined(CTI::Helpers::write_byte($fp, $mode)) or return undef;
  return 1;
}

=head1 req_join

C<req_join IOHANDLE MODE>

変換結果の結合を要求します。

=head2 引数

=over

=item IOHANDLE 入出力ストリーム(通常はソケット)

=back

=head2 戻り値

B<成功なら1,失敗ならundef>

=cut
sub req_join (*) {
  my ($fp) = @_;
  $fp = Symbol::qualify_to_ref($fp, caller());

  my $payload = 1;
  defined(CTI::Helpers::write_int($fp, $payload)) or return undef;
  defined(CTI::Helpers::write_byte($fp, CTI::CTIP2::CTIP::REQ_JOIN)) or return undef;
  return 1;
}

=head1 req_eof

C<req_eof IOHANDLE>

データを終了します。

=head2 引数

=over

=item IOHANDLE 入出力ストリーム(通常はソケット)

=back

=head2 戻り値

B<成功なら1,失敗ならundef>

=cut
sub req_eof (*) {
  my ($fp) = @_;
  $fp = Symbol::qualify_to_ref($fp, caller());

  my $payload = 1;
  defined(CTI::Helpers::write_int($fp, $payload)) or return undef;
  defined(CTI::Helpers::write_byte($fp, CTI::CTIP2::CTIP::REQ_EOF)) or return undef;
  return 1;
}

=head1 req_property

C<req_property IOHANDLE NAME VALUE>

プロパティを送ります。

=head2 引数

=over

=item IOHANDLE 入出力ストリーム(通常はソケット)

=item NAME 名前

=item VALUE 値

=back

=head2 戻り値

B<成功なら1,失敗ならundef>

=cut
sub req_property (*$$) {
  my ($fp, $name, $value) = @_;
  $fp = Symbol::qualify_to_ref($fp, caller());

  my $payload = length($name) + length($value) + 5;
  defined(CTI::Helpers::write_int($fp, $payload)) or return undef;
  defined(CTI::Helpers::write_byte($fp, CTI::CTIP2::CTIP::REQ_PROPERTY)) or return undef;
  defined(CTI::Helpers::write_bytes($fp, $name)) or return undef;
  defined(CTI::Helpers::write_bytes($fp, $value)) or return undef;
  return 1;
}


=head1 req_server_main

C<req_server_main IOHANDLE URI>

サーバー側データの変換を要求します。

=head2 引数

=over

=item IOHANDLE 入出力ストリーム(通常はソケット)

=item URI 変換前データのURI

=back

=head2 戻り値

B<成功なら1,失敗ならundef>

=cut
sub req_server_main (*$) {
  my $fp = shift;
  my $uri = shift;
  $fp = Symbol::qualify_to_ref($fp, caller());

  my $payload = length($uri) + 3;
  defined(CTI::Helpers::write_int($fp, $payload)) or return undef;
  defined(CTI::Helpers::write_byte($fp, CTI::CTIP2::CTIP::REQ_SERVER_MAIN)) or return undef;
  defined(CTI::Helpers::write_bytes($fp, $uri)) or return undef;
  return 1;
}

=head1 req_resource

C<req_resource IOHANDLE URI [MIME_TYPE ENCODING LENGTH]>

リソースの開始を通知します。

=head2 引数

=over

=item IOHANDLE 入出力ストリーム(通常はソケット)

=item URI URI

=item MIME_TYPE MIME型

=item ENCODING エンコーディング

=item LENGTH 予想されるデータサイズ（不明なら-1）

=back

=head2 戻り値

B<成功なら1,失敗ならundef>

=cut
sub req_resource (*$;$$$) {
  my $fp = shift;
  my $uri = shift;
  my $mime_type = shift || 'text/css';
  my $encoding = shift || '';
  my $length = shift || -1;
  $fp = Symbol::qualify_to_ref($fp, caller());

  my $payload = length($uri) + length($mime_type) + length($encoding) + 7 + 8;
  defined(CTI::Helpers::write_int($fp, $payload)) or return undef;
  defined(CTI::Helpers::write_byte($fp, CTI::CTIP2::CTIP::REQ_START_RESOURCE)) or return undef;
  defined(CTI::Helpers::write_bytes($fp, $uri)) or return undef;
  defined(CTI::Helpers::write_bytes($fp, $mime_type)) or return undef;
  defined(CTI::Helpers::write_bytes($fp, $encoding)) or return undef;
  defined(CTI::Helpers::write_long($fp, $length)) or return undef;
  return 1;
}

=head1 req_start_main

C<req_start_main IOHANDLE URI [MIME_TYPE ENCODING　LENGTH]>

本体の開始を通知します。

=head2 引数

=over

=item IOHANDLE 入出力ストリーム(通常はソケット)

=item URI URI

=item MIME_TYPE MIME型

=item ENCODING エンコーディング

=item LENGTH 予想されるデータサイズ（不明なら-1）

=back

=head2 戻り値

B<成功なら1,失敗ならundef>

=cut
sub req_start_main (*$;$$$) {
  my $fp = shift;
  my $uri = shift;
  my $mime_type = shift || 'text/html';
  my $encoding = shift || '';
  my $length = shift || -1;
  $fp = Symbol::qualify_to_ref($fp, caller());

  my $payload = length($uri) + length($mime_type) + length($encoding) + 7 + 8;
  defined(CTI::Helpers::write_int($fp, $payload)) or return undef;
  defined(CTI::Helpers::write_byte($fp, CTI::CTIP2::CTIP::REQ_START_MAIN)) or return undef;
  defined(CTI::Helpers::write_bytes($fp, $uri)) or return undef;
  defined(CTI::Helpers::write_bytes($fp, $mime_type)) or return undef;
  defined(CTI::Helpers::write_bytes($fp, $encoding)) or return undef;
  defined(CTI::Helpers::write_long($fp, $length)) or return undef;
  return 1;
}

=head1 req_write

C<req_write IOHANDLE DATA [LENGTH]>

データを送ります。

=head2 引数

=over

=item IOHANDLE 入出力ストリーム(通常はソケット)

=item DATA データ

=item LENGTH データの長さ

=back

=head2 戻り値

B<成功なら1,失敗ならundef>

=cut
sub req_write (*$;$) {
  my ($fp, $b) = @_;
  $fp = Symbol::qualify_to_ref($fp, caller());
  my $len = length($b);
  $len = $_[2] ? ($_[2] >= $len ? $len : $_[2]) : $len;

  my $payload = $len + 1;
  defined(CTI::Helpers::write_int($fp, $payload)) or return undef;
  defined(CTI::Helpers::write_byte($fp, CTI::CTIP2::CTIP::REQ_DATA)) or return undef;
  defined(CTI::Helpers::write($fp, $b, $len)) or return undef;
  return 1;
}

=head1 req_write

C<req_write IOHANDLE>

通信を終了します。

=head2 引数

=over

=item IOHANDLE 入出力ストリーム(通常はソケット)

=back

=head2 戻り値

B<成功なら1,失敗ならundef>

=cut
sub req_close (*) {
  my ($fp) = @_;
  $fp = Symbol::qualify_to_ref($fp, caller());

  my $payload = 1;
  defined(CTI::Helpers::write_int($fp, $payload)) or return undef;
  defined(CTI::Helpers::write_byte($fp, CTI::CTIP2::CTIP::REQ_CLOSE)) or return undef;
  return 1;
}

=head1 res_next

C<res_next IOHANDLE>

次のレスポンスを取得します。

レスポンス(array)には次のデータが含まれます。

- 'type' レスポンスタイプ
- 'block_id' フラグメントID
- 'code' メッセージコード
- 'message' メッセージ
- 'args' メッセージ引数
- 'bytes' データのバイト列
- 'mode' 中断モード
- 'uri' 結果/リソースのURI
- 'mime_type' 結果/リソースのMIME-TYPE
- 'encoding' 結果/リソースのキャラクタ・エンコーディング
- 'length' 結果/リソースの予期された長さ

=head2 引数

=over

=item IOHANDLE 入出力ストリーム(通常はソケット)

=back

=head2 戻り値

B<レスポンス,失敗なら空のハッシュ>

=cut
sub res_next (*) {
  my $fp = shift;
  $fp = Symbol::qualify_to_ref($fp, caller());
  
  my $payload = CTI::Helpers::read_int($fp);
  defined($payload) or return ();
  my $type = CTI::Helpers::read_byte($fp);
  defined($type) or return ();
  
  # printf "[%X]\n", $type;
  if ($type == CTI::CTIP2::CTIP::RES_EOF
  || $type == CTI::CTIP2::CTIP::RES_ADD_BLOCK
  || $type == CTI::CTIP2::CTIP::RES_NEXT) {
    # EOFまたはブロック追加または継続
    return (
      'type' => $type,
    );
      
  } elsif ($type == CTI::CTIP2::CTIP::RES_START_DATA) {
  	# データ開始
    my $uri = CTI::Helpers::read_bytes($fp);
    defined($uri) or return ();
    my $mime_type = CTI::Helpers::read_bytes($fp);
    defined($mime_type) or return ();
    my $encoding = CTI::Helpers::read_bytes($fp);
    defined($encoding) or return ();
    my $length = CTI::Helpers::read_long($fp);
    defined($length) or return ();
    return (
      'type' => $type,
      'uri' => $uri,
      'mime_type' => $mime_type,
      'encoding' => $encoding,
      'length' => $length
    );
      
  } elsif ($type == CTI::CTIP2::CTIP::RES_MAIN_LENGTH || $type == CTI::CTIP2::CTIP::RES_MAIN_READ) {
  	# 進行状況
    my $length = CTI::Helpers::read_long($fp);
    defined($length) or return ();
    return (
      'type' => $type,
      'length' => $length
    );
      
  } elsif ($type == CTI::CTIP2::CTIP::RES_INSERT_BLOCK || $type == CTI::CTIP2::CTIP::RES_CLOSE_BLOCK) {
  	# ブロック挿入 / クローズ
    my $block_id = CTI::Helpers::read_int($fp);
    defined($block_id) or return ();
    return (
      'type' => $type,
      'block_id' => $block_id
    );
      
  } elsif ($type == CTI::CTIP2::CTIP::RES_MESSAGE) {
  	# メッセージ
    my $code = CTI::Helpers::read_short($fp);
  	$payload -= 1 + 2;
    defined($code) or return ();
    my $message = CTI::Helpers::read_bytes($fp);
    defined($message) or return ();
    $payload -= 2 + length($message);
    my @args = ();
    while ($payload > 0) {
      my $arg = CTI::Helpers::read_bytes($fp);
      defined($arg) or return ();
      $payload -= 2 + length($arg);
      push(@args, $arg);
    }
    return (
      'type' => $type,
      'code' => $code,
      'message' => $message,
      'args' => \@args
    );
      
  } elsif ($type == CTI::CTIP2::CTIP::RES_BLOCK_DATA) {
  	# ブロックデータ
    my $length = $payload - 5;
    my $block_id = CTI::Helpers::read_int($fp);
    my $bytes = CTI::Helpers::read($fp, $length);
    defined($bytes) or return ();
    return (
        'type' => $type,
        'block_id' => $block_id,
        'bytes' => $bytes,
        'length' => $length
    );
  
  } elsif ($type == CTI::CTIP2::CTIP::RES_DATA) {
  	# 単純データ
    my $length = $payload - 1;
    my $bytes = CTI::Helpers::read($fp, $length);
    defined($bytes) or return ();
    return (
        'type' => $type,
        'bytes' => $bytes,
        'length' => $length
    );
  
  } elsif ($type == CTI::CTIP2::CTIP::RES_RESOURCE_REQUEST) {
  	# リソース要求
    my $uri = CTI::Helpers::read_bytes($fp);
    defined($uri) or return ();
    return (
        'type' => $type,
        'uri' => $uri
     );
  
  } elsif ($type == CTI::CTIP2::CTIP::RES_ABORT) {
  	# 中断
    my $mode = CTI::Helpers::read_byte($fp);
    defined($mode) or return ();
    my $code = CTI::Helpers::read_short($fp);
  	$payload -= 1 + 1 + 2;
    defined($code) or return ();
    my $message = CTI::Helpers::read_bytes($fp);
    defined($message) or return ();
    $payload -= 2 + length($message);
    my @args = ();
    while ($payload > 0) {
      my $arg = CTI::Helpers::read_bytes($fp);
      defined($arg) or return ();
      $payload -= 2 + length($arg);
      push(@args, $arg);
    }
    return (
      'type' => $type,
      'mode' => $mode,
      'code' => $code,
      'message' => $message,
      'args' => \@args
    );
  
  } else {
      warn ("Bad response type:$type");
      return ();
  }
}
