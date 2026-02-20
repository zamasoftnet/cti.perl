=head1 NAME

CTI::Builder::NullBuilder - 出力しない。

=head2 概要

変換結果をどこにも出力しません。

=head2 作者

$Date: 2010-01-05 15:54:41 +0900 (2010年01月05日 (火)) $ MIYABE Tatsuhiko

=cut
package CTI::Builder::NullBuilder;

require Exporter;
@ISA	= qw(Exporter);
@EXPORT_OK	= qw(build);

use strict;

=head1 CTI::Builder::NullBuilder

C<new CTI::Builder::NullBuilder >

結果を破棄するオブジェクトを構築します。

=cut
sub new ($) {
  my ($class) = @_;
  
  my $self = {};
  bless $self, $class;
  return $self;
}

sub add_block ($) {
  # NOP
}

sub insert_block_before ($$) {
  # NOP
}

sub write ($$$) {
  # NOP
}

sub close_block ($$) {
  # NOP
}

sub serial_write ($$) {
  # NOP
}

sub finish ($) {
  # NOP
}

sub dispose ($) {
  # NOP
}
