=head1 NAME

CTI::CTIP2::ResourceOutputTie - リソースキャプチャのためのハンドルトラップ

=head2 概要

リソースをキャプチャしてサーバーへ送るため、ハンドルへの操作をトラップするタイです。
詳細は、Perlのtie関数およびTIEHANDLEについての解説を参照してください。

通常、プログラマがこのパッケージを直接使う必要はありません。

=head2 作者

$Date: 2009-12-14 13:55:18 +0900 (2009年12月14日 (月)) $ MIYABE Tatsuhiko

=cut
package CTI::CTIP2::ResourceOutputTie;

use strict;
use Encode;
use Symbol;
use CTI::Helpers;
use CTI::CTIP2::CTIP;
use utf8;

sub TIEHANDLE ($*$) {
  my $class = shift;
  my $fp = shift;
  my $header = shift;
  $fp = Symbol::qualify_to_ref($fp, caller);
  my $self = {
    'FP' => $fp,
    'buffer' => '',
    'header' => $header
  };
  bless $self, $class;
}

sub send_buffer {
  my $self = shift;
  my $flush = shift;

  my $fp = $self->{FP};
  for (;;) {
  	my $bufferLength = length($self->{buffer});
    if (!$flush && $bufferLength < CTI::Helpers::BUFFER_SIZE) {
      last;
    }
    my $buff = substr($self->{buffer}, 0, CTI::Helpers::BUFFER_SIZE);
    my $len = length($buff);
    if ($len <= 0) {
      last;
    }
    $self->{buffer} = substr($self->{buffer}, $len, $bufferLength - $len);
    defined(CTI::CTIP2::CTIP::req_write($fp, $buff, $len)) or return undef;
  }
  return 1;
}

sub PRINT {
    my $self = shift;
    my $data = shift;
    if (utf8::is_utf8($data)) {
      $data = encode('utf-8', $data)
    }
    
    if ($self->{header}) {
    	my $len = length($data);
		for (my $i = 0; $i < $len; $i++) {
		    my $c = substr($data, $i, 1);
		    if ($c eq "\n") {
		    	if ($self->{header} == 1) {
		    		$self->{header} = 2;
		    	}
		    	elsif ($self->{header} == 2) {
		    		$self->{header} = 0;
		    		$data = substr($data, $i + 1);
		    		last;
		    	}
		    }
		    elsif ($c ne "\n") {
		    	$self->{header} = 1;
		    }
		}
		if ($self->{header}) {
			return;
		}
    }
	$self->{buffer} .= $data;
	$self->send_buffer(0);
}

sub PRINTF {
    my $self = shift;
    my $format = shift;
    my $data = sprintf($format, @_);
    if (utf8::is_utf8($data)) {
      $data = encode('utf-8', $data)
    }
    
    return $self->PRINT($data);
}

sub WRITE {
    my $self = shift;
    my($buf,$len,$offset) = @_;
    return $self->PRINT($buf, $offset, $len);
}

sub BINMODE {
	# ignore
}

sub FILENO {
	return undef;
}

sub CLOSE {
	my $self = shift;
	
	return $self->send_buffer(1);
}

return 1;