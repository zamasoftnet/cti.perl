=head1 NAME

CTI::CTIP2::MainOutputTie - 本体キャプチャのためのハンドルトラップ

=head2 概要

本体をキャプチャしてサーバーへ送るため、ハンドルへの操作をトラップするタイです。
詳細は、Perlのtie関数およびTIEHANDLEについての解説を参照してください。

通常、プログラマがこのパッケージを直接使う必要はありません。

=head2 作者

$Date: 2009-12-14 13:55:18 +0900 (2009年12月14日 (月)) $ MIYABE Tatsuhiko

=cut
package CTI::CTIP2::MainOutputTie;

use strict;
use Encode;
use Symbol;
use CTI::Helpers;
use CTI::CTIP2::CTIP;

sub TIEHANDLE ($*$$) {
  my ($class, $fp, $session, $header) = @_;
  $fp = Symbol::qualify_to_ref($fp, caller);
  
  my $self = {
    'FP' => $fp,
    'session' => $session,
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
    $self->{buffer} = substr($self->{buffer}, $len);
    my $packet = pack('NC', $len + 1, CTI::CTIP2::CTIP::REQ_DATA).$buff;
    $len = length($packet);
    my ($rin,$win,$ein) = ('','','');
    my $fn = fileno($fp);
    vec($rin, $fn, 1) = 1;
    vec($win, $fn, 1) = 1;
    $ein = $rin | $win;
    for (;;) {
      my ($rout,$wout,$eout);
      my $status = select($rout = $rin, $wout = $win, $eout = $ein, undef);
      defined($status) or return undef;
      if ($len > 0 && vec($wout, $fn, 1)) {
        my $rlen = syswrite($fp, $packet, $len, 0);
        defined($rlen) or return undef;
      	$packet = substr($packet, $rlen);
        $len -= $rlen;
      }
      if (vec($rout, $fn, 1)) {
        defined($self->{session}->build_next()) or return undef;
      }
	  if ($len <= 0) {
        last;
      }
    }
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