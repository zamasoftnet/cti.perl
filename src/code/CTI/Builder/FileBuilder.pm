=head1 NAME

CTI::Builder::FileBuilder - ファイルの構築。

=head2 概要

変換結果をファイルとして構築します。

=head2 作者

$Date: 2010-10-31 15:18:36 +0900 (2010年10月31日 (日)) $ MIYABE Tatsuhiko

=cut
package CTI::Builder::FileBuilder;

require CTI::Builder::StreamBuilder;
@ISA	= qw(CTI::Builder::StreamBuilder);
@EXPORT_OK	= qw(build);

use strict;
use File::Temp;
use Symbol;

=head1 CTI::Builder::FileBuilder

C<new CTI::Builder::FileBuilder FILE>

指定したファイルに結果を出力するオブジェクトを構築します。

=head2 引数

=over

=item FILE

	出力先ファイル名。

=back

=cut
sub new ($$) {
  my ($class, $file) = @_;
  my $self = CTI::Builder::StreamBuilder->new(undef);
  
  bless $self, $class;
  $self->{FILE} = $file;
  return $self;
}

sub serial_write ($$) {
  my ($self, $data) = @_;
  
  if (!defined($self->{OUT})) {
  	open($self->{OUT}, '>'.$self->{FILE});
  }
  my $out = $self->{OUT};
  print $out $data;
}

sub finish ($) {
  my ($self) = @_;
  if (!defined($self->{OUT})) {
    open($self->{OUT}, '>'.$self->{FILE});
    binmode $self->{OUT};
    $self->SUPER::finish();
  }
  close($self->{OUT});
  $self->{OUT} = undef;
}
