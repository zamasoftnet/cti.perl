=head1 NAME

CTI::Fragment - フラグメント

=head2 概要

断片化された変換結果です。

通常、プログラマがこのパッケージを直接使う必要はありません。

=head2 作者

$Date: 2009-12-14 13:55:18 +0900 (2009年12月14日 (月)) $ MIYABE Tatsuhiko

=cut
package CTI::Builder::Fragment;

require Exporter;
@ISA	= qw(Exporter);

use strict;
use Symbol;
use CTI::Helpers;

=head1 定数

=head2 FRG_MEM_SIZE

メモリ上のフラグメントの最大サイズです。

フラグメントがこの大きさを超えるとディスクに書き込みます。

=cut
sub FRG_MEM_SIZE { return 256; }

=head2 ON_MEMORY

メモリ上に置かれるデータの最大サイズです。

メモリ上のデータがこのサイズを超えると、
FRG_MEM_SIZEとは無関係にディスクに書き込まれます。

=cut
sub ON_MEMORY { return 1024 * 1024; }

=head2 SEGMENT_SIZE

一時ファイル内のセグメントのサイズです。。

=cut
sub SEGMENT_SIZE { return 8192; }

=head1 CTI::Fragment

C<new CTI::Fragment ID>

フラグメントを作成します。

=head2 引数

=over

=item ID 断片ID

=back

=cut
sub new ($$) {
  my $class = shift;
  my $id = shift;
  my $self = {
    'segments' => undef,
    'segLen' => undef,
    'id' => $id,
    'prev' => undef,
    'next' => undef,
    'length' => 0,
    'buffer' => ''
  };
  
  bless $self, $class;
  return $self;
}

=head1 CTI::Fragment->write

C<write TEMP_FILE BYTES LENGTH ON_MEMORY SEGMENT>

フラグメントにデータを書き込みます。

=head2 引数

=over

=item TEMP_FILE 一時ファイル

=item ON_MEMORY メモリ上のデータ量を保持するスカラ変数へのB<参照>

=item SEGMENT セグメント番号シーケンスへのB<参照>

=item BYTES データ

=back

=head2 戻り値

B<成功なら書き込んだバイト数,失敗ならundef>

=cut
sub write ($$$$$) {
  my $self = shift;
  my $tempFile = shift;
  my $onMemory = shift;
  my $segment = shift;
  my $bytes = shift;
  
  my $len = length($bytes);
  if (!defined($self->{segments}) &&
      ($self->{length} + $len) <= (FRG_MEM_SIZE) &&
      ($$onMemory + $len) <= (ON_MEMORY)) {
    $self->{buffer} .= $bytes;
    $$onMemory += $len;
  } else {
  	if (defined($self->{buffer})) {
  	  my $wlen = $self->raf_write($tempFile, $segment, $self->{buffer});
      defined($wlen) or return undef;
      $$onMemory -= $wlen;
      $self->{buffer} = undef;
  	}
    $len = $self->raf_write($tempFile, $segment, $bytes);
    defined($len) or return undef;
  }
  $self->{length} += $len;
  return $len;
}

=head1 CTI::Fragment->raf_write

C<write TEMP_FILE SEGMENT BYTES>

一時ファイルにデータを書き込みます。

=head2 引数

=over

=item TEMP_FILE 一時ファイル

=item SEGMENT セグメント番号シーケンスへのB<参照>

=item BYTES データ

=back

=head2 戻り値

B<成功なら書き込んだバイト数,失敗ならundef>

=cut
sub raf_write ($*$$) {
  my $self = shift;
  my $tempFile = shift;
  my $segment = shift;
  my $bytes = shift;
  $tempFile = Symbol::qualify_to_ref($tempFile, caller());
  
  if (!defined($self->{segments})) {
    $self->{segments} = [$$segment++];
    $self->{segLen} = 0;
  }
  
  my $segments = $self->{segments};
  
  my $written = 0;
  my $len;
  while (($len = length($bytes)) > 0) {
	if ($self->{segLen} == (SEGMENT_SIZE)) {
		$segments->[@$segments] = $$segment++;
		$self->{segLen} = 0;
	}
	my $seg = $segments->[@$segments - 1];
	my $max = (SEGMENT_SIZE) - $self->{segLen};
	my $wlen = ($len > $max) ? $max : $len;
	my $wpos = $seg * (SEGMENT_SIZE) + $self->{segLen};
	sysseek($tempFile, $wpos, 0) or return undef;
	defined($wlen = CTI::Helpers::write($tempFile, $bytes, $wlen)) or return undef;
	$self->{segLen} += $wlen;
	$written += $wlen;
	$bytes = substr($bytes, $wlen);
  }
  return $written;
}

=head1 CTI::Fragment->flush

C<flush TEMP_FILE OUTPUTHANDLE>

フラグメントの内容を吐き出して、フラグメントを破棄します。

=head2 引数

=over

=item TEMP_FILE 一時ファイル

=item OUTPUTHANDLE 出力先ハンドル

=back

=head2 戻り値

B<成功なら1,失敗ならundef>

=cut
sub flush ($**) {
  my $self = shift;
  my $tempFile = shift;
  my $out = shift;
  $tempFile = Symbol::qualify_to_ref($tempFile, caller());
  $out = Symbol::qualify_to_ref($out, caller());

  if (!defined($self->{segments})) {
    defined(CTI::Helpers::write($out, $self->{buffer}, $self->{length})) or return undef;
    undef($self->{buffer});
  }
  else {
  	my $segments = $self->{segments};
    my $segcount = @$segments;
    my $i;
    for ($i = 0; $i < $segcount - 1; ++$i) {
      my $seg = $segments->[$i];
      my $rpos = $seg * (SEGMENT_SIZE);
      sysseek($tempFile, $rpos, 0) or return undef;
      my $buff = CTI::Helpers::read($tempFile, (SEGMENT_SIZE));
      defined($buff) or return undef;
      defined(CTI::Helpers::write($out, $buff)) or return undef;
    }
    my $seg = $segments->[$segcount - 1];
    my $rpos = $seg * (SEGMENT_SIZE);
    sysseek($tempFile, $rpos, 0) or return undef;
    my $buff = CTI::Helpers::read($tempFile, $self->{segLen});
    defined($buff) or return undef;
    defined(CTI::Helpers::write($out, $buff)) or return undef;
  }
  return 1;
}
