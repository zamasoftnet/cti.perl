=head1 NAME

CTI::Helpers - 入出力ユーティリティ

=head2 概要

ストリームへデータを入出力するためのユーティリティです。
これらの関数は、ノンブロッキングI/Oに対しても与えられた(要求される)データを全て出力(入力)します。

通常、プログラマがこのパッケージを直接使う必要はありません。

=head2 作者

$Date: 2011-03-15 14:56:53 +0900 (2011年03月15日 (火)) $ MIYABE Tatsuhiko

=cut
package CTI::Helpers;

require Exporter;
@ISA	= qw(Exporter);

use strict;
use Symbol;

=head1 定数

=head2 BUFFER_SIZE

パケットの送信に使うバッファのサイズです。

=cut
sub BUFFER_SIZE { return 8192; }

=head1 write_int

C<write_int OUTHANDLE INTEGER>

32ビット数値をビッグインディアンで書き出します。

=head2 引数

=over

=item OUTHANDLE

	出力先ハンドル

=item INTEGER

	32ビット整数

=back

=head2 戻り値

B<成功なら書き込んだバイト数,失敗ならundef>

=cut
sub write_int (*$) {
  my $fp = shift;
  my $a = shift;
  $fp = Symbol::qualify_to_ref($fp, caller());
  
  my $data = pack('N', $a);
  return CTI::Helpers::write($fp, $data);
}


=head1 write_long

C<write_int OUTHANDLE LONG>

64ビット数値をビッグインディアンで書き出します。

=head2 引数

=over

=item OUTHANDLE

	出力先ハンドル

=item LONG

	64ビット整数

=back

=head2 戻り値

B<成功なら書き込んだバイト数,失敗ならundef>

=cut
sub write_long (*$) {
  my $fp = shift;
  my $a = shift;
  $fp = Symbol::qualify_to_ref($fp, caller());
  
  my $data = pack('NN', $a >> 32, $a & 0xFFFFFFFF);
  return CTI::Helpers::write($fp, $data);
}

=head1 write_byte

C<write_byte OUTHANDLE BYTE>

8ビット数値を書き出します。

=head2 引数

=over

=item OUTHANDLE

	出力先ハンドル

=item BYTE

	8ビット整数

=back

=head2 戻り値

B<成功なら書き込んだバイト数,失敗ならundef>

=cut
sub write_byte (*$) {
  my $fp = shift;
  my $b = shift;
  $fp = Symbol::qualify_to_ref($fp, caller());
  
  my $data = chr($b);
  return CTI::Helpers::write($fp, $data);
}

=head1 write_bytes

C<write_bytes OUTHANDLE BYTES>

バイト数を16ビットビッグインディアンで書き出した後、バイト列を書き出します。

=head2 引数

=over

=item OUTHANDLE

	出力先ハンドル

=item BYTES

	バイト列

=back

=head2 戻り値

B<成功なら書き込んだバイト数,失敗ならundef>

=cut
sub write_bytes (*$) {
  my $fp = shift;
  my $b = shift;
  $fp = Symbol::qualify_to_ref($fp, caller());
  
  my $data = pack('n', length($b));
  defined(CTI::Helpers::write($fp, $data)) or return undef;
  return CTI::Helpers::write($fp, $b);
}

=head1 write

C<write OUTHANDLE BYTES [ LENGTH] >

バイト列を書き出します。

=head2 引数

=over

=item OUTHANDLE

	出力先ハンドル

=item BYTES

	バイト列

=item LENGTH

	長さ

=back

=head2 戻り値

B<成功なら書き込んだバイト数,失敗ならundef>

=cut
sub write (*$;$) {
  my $fp = shift;
  my $data = shift;
  my $len = shift || length($data);
  $fp = Symbol::qualify_to_ref($fp, caller());
  
  my $off = 0;
  while ($len) {
    my $written;
    $written = syswrite($fp, $data, $len, $off);
    defined ($written) or return undef;
    $len -= $written;
    $off += $written;
  }
  return $off;
}

=head1 read_int

C<read_int INHANDLE>

32ビットビッグインディアン数値を読み込みます。

=head2 引数

=over

=item INHANDLE

	入力元ハンドル

=back

=head2 戻り値

B<成功なら32ビット整数,失敗ならundef>

=cut
sub read_int (*) {
  my $fp = shift;
  $fp = Symbol::qualify_to_ref($fp, caller());
  
  my $b = CTI::Helpers::read($fp, 4);
  defined($b) or return undef;
  $b = unpack('N', $b);
  if ($b >> 31 != 0) {
  	$b = -(($b ^ 0xFFFFFFFF) + 1);
  }
  return $b;
}

=head1 read_short

C<read_short INHANDLE>

16ビットビッグインディアン数値を読み込みます。

=head2 引数

=over

=item INHANDLE

	入力元ハンドル

=back

=head2 戻り値

B<成功なら16ビット整数,失敗ならundef>

=cut
sub read_short (*) {
  my $fp = shift;
  $fp = Symbol::qualify_to_ref($fp, caller());
  
  my $b = CTI::Helpers::read($fp, 2);
  defined($b) or return undef;
  $b = unpack('n', $b);
  if ($b >> 15 != 0) {
  	$b = -(($b ^ 0xFFFF) + 1);
  }
  return $b;
}

=head1 read_long

C<read_long INHANDLE>

64ビットビッグインディアン数値を読み込みます。

=head2 引数

=over

=item INHANDLE

	入力元ハンドル

=back

=head2 戻り値

B<成功なら64ビット整数,失敗ならundef>

=cut
sub read_long (*) {
  my $fp = shift;
  $fp = Symbol::qualify_to_ref($fp, caller());
  
  my $b = CTI::Helpers::read($fp, 4);
  defined($b) or return undef;
  my $h = unpack('N', $b);
  my $b = CTI::Helpers::read($fp, 4);
  defined($b) or return undef;
  my $l = unpack('N', $b);
  if ($h >> 31 != 0) {
  	$h ^= 0xFFFFFFFF;
  	$l ^= 0xFFFFFFFF;
  	$b = ($h << 32) | $l; 
  	$b = -($b + 1);
  }
  else {
  	$b = ($h << 32) | $l; 
  }
  return $b;
}

=head1 read_byte

C<read_byte INHANDLE>

8ビット数値を読み込みます。

=head2 引数

=over

=item INHANDLE

	入力元ハンドル

=back

=head2 戻り値

B<成功なら8ビット整数,失敗ならundef>

=cut
sub read_byte (*) {
  my $fp = shift;
  $fp = Symbol::qualify_to_ref($fp, caller());
  
  my $b = CTI::Helpers::read($fp, 1);
  defined($b) or return undef;
  return ord($b);
}

=head1 read_bytes

C<read_bytes INHANDLE>

16ビットビッグインディアン数値を読み込み、そのバイト数だけバイト列を読み込みます。

=head2 引数

=over

=item INHANDLE

	入力元ハンドル

=back

=head2 戻り値

B<成功ならバイト列,失敗ならundef>

=cut
sub read_bytes (*) {
  my $fp = shift;
  $fp = Symbol::qualify_to_ref($fp, caller());
  
  my $len = CTI::Helpers::read_short($fp);
  defined($len) or return undef;
  my $b = CTI::Helpers::read($fp, $len);
  defined($b) or return undef;
  return $b;
}

=head1 read

C<read INHANDLE LENGTH>

バイト列を読み込みます。

=head2 引数

=over

=item INHANDLE

	入力元ハンドル

=item LENGTH 要求されるバイト数

=back

=head2 戻り値

B<成功ならバイト列,失敗ならundef>

=cut
sub read (*$) {
  my $fp = shift;
  my $len = shift;
  $fp = Symbol::qualify_to_ref($fp, caller());
  
  my $result = '';
  for (;;) {
    if ($len <= 0) {
      return $result;
    }
    my $data;
    my $read = sysread($fp, $data, $len);
    defined($read) && $read > 0 or return undef;
    $len -= $read;
    $result .= $data;
  }
}

