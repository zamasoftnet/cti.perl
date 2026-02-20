=head1 NAME

CTI::Results::SingleResult - １つの結果を構築。

=head2 概要

最初の結果だけ構築し、あとは無視します。

=head2 作者

$Date: 2010-01-05 15:54:41 +0900 (2010年01月05日 (火)) $ MIYABE Tatsuhiko

=cut
package CTI::Results::SingleResult;

require Exporter;
@ISA	= qw(Exporter);
@EXPORT_OK	= qw(build);

use strict;
use CTI::Builder::NullBuilder;

=head1 CTI::Results::SingleResult

C<new CTI::Results::SingleResult BUILDER HEADER>

ビルダに対して結果を出力するオブジェクトを構築します。

=head2 引数

=over

=item BUILDER

	出力先ビルダ。

=item HEADER

	1ならContent-Type, Content-Lengthヘッダを出力する。

=back

=cut
sub new ($$;$) {
  my ($class, $builder, $header) = @_;
  my $self = {
    'builder' => $builder,
    'header' => $header
  };
  
  bless $self, $class;
  return $self;
}

sub next_builder ($%) {
  my ($self, %opts) = @_;
  if ($self->{builder}) {
    my $builder = $self->{builder};
  	if ($self->{header}) {
  	  if ($opts{mime_type}) {
  		print "Content-Type: ".$opts{mime_type}."\n";
  	  }
  	  if ($opts{length} != -1) {
  		print "Content-Length: ".$opts{length}."\n\n";
  	  }
  	  else {
  	  	$builder->{header} = 1;
  	  }
  	}
    undef $self->{builder};
    return $builder;
  }
  return CTI::Builder::NullBuilder->new;
}