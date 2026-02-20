=head1 NAME

CTI::Results::DirectoryResults - ディレクトリに複数の結果を保存。

=head2 概要

複数の変換結果をディレクトリに保存します。

=head2 作者

$Date: 2010-01-05 15:54:41 +0900 (2010年01月05日 (火)) $ MIYABE Tatsuhiko

=cut
package CTI::Results::DirectoryResults;

require Exporter;
@ISA	= qw(Exporter);
@EXPORT_OK	= qw(build);

use strict;
use CTI::Builder::FileBuilder;

=head1 CTI::Results::DirectoryResults

C<new CTI::Results::DirectoryResults DIR PREFIX SUFFIX>

指定したディレクトリに、指定したファイル名で出力するオブジェクトを構築します。

こちらは、複数の結果をファイルとして出力するディレクトリ名を直接設定出来ます。
ファイル名は PREFIX ページ番号 SUFFIX をつなげたものです。

=head2 引数

=over

=item DIRNAME

	出力先ディレクトリ名。

=item PREFIX

	出力するファイルの名前の前に付ける文字列。

=item SUFFIX

	出力するファイルの名前の後に付ける文字列。

=back

=cut
sub new ($$;$$) {
  my ($class, $dir, $prefix, $suffix) = @_;
  my $self = {
    'dir' => $dir,
    'prefix' => $prefix,
    'suffix' => $suffix,
    'counter' => 0,
  };
  
  bless $self, $class;
  return $self;
}

sub next_builder ($%) {
  my $self = shift;
  
  $self->{counter}++;
  my $dir = $self->{dir};
  my $prefix = $self->{prefix};
  my $counter = $self->{counter};
  my $suffix = $self->{suffix};
  my $builder = CTI::Builder::FileBuilder->new("$dir/$prefix".$counter.$suffix);
  return $builder;
}