=head1 NAME

CTI::Builder::StreamBuilder - ストリームに出力。

=head2 概要

変換結果をストリーム（ファイルハンドル）に出力します。

=head2 作者

$Date: 2011-06-29 17:19:34 +0900 (2011年06月29日 (水)) $ MIYABE Tatsuhiko

=cut
package CTI::Builder::StreamBuilder;

require Exporter;
@ISA	= qw(Exporter);
@EXPORT_OK	= qw(build);

use strict;
use File::Temp;
use Symbol;
use CTI::Builder::Fragment;

=head1 CTI::Builder::StreamBuilder

C<new CTI::Builder::StreamBuilder >

指定したハンドルに結果を出力するオブジェクトを構築します。

=head2 引数

=over

=item OUTPUTHANDLE

	出力先ハンドル。

=back

=cut
sub new ($*) {
  my ($class, $out) = @_;
  if ($out) {
    $out = Symbol::qualify_to_ref($out, caller());
  }

  my $self = {
    'OUT' => $out,
    'tempFile' => undef,
    'tempFileName' => undef,
    'frgs' => [ ],
    'first' => undef,
    'last' => undef,
    'onMemory' => 0,
    'length' => 0,
    'segment' => 0,
    'header' => 0
  };
  
  bless $self, $class;
  return $self;
}

sub add_block ($) {
  my ($self) = @_;
  my $frgs = $self->{frgs};
  my $first = $self->{first};
  my $last = $self->{last};
	 
  my $id = @$frgs;
  my $frg = CTI::Builder::Fragment->new($id);
  $frgs->[$id] = $frg;
  if (!$first) {
    $self->{first} = $frg;
  }
  else {
    $last->{next} = $frg;
    $frg->{prev} = $last;
  }
  $self->{last} = $frg;
}

sub insert_block_before ($$) {
  my ($self, $anchorId) = @_;
  my $frgs = $self->{frgs};
  my $first = $self->{first};
  my $last = $self->{last};
	 
  my $id = @$frgs;
  my $anchor = $frgs->[$anchorId];
  my $frg = CTI::Builder::Fragment->new($id);
  $frgs->[$id] = $frg;
  $frg->{prev} = $anchor->{prev};
  $frg->{next} = $anchor;
  $anchor->{prev}->{next} = $frg;
  $anchor->{prev} = $frg;
  if ($first->{id} == $anchor->{id}) {
    $self->{first} = $frg;
  }
}

sub write ($$$) {
  my ($self, $id, $data) = @_;
  
  my $tempFile;
  my $tempFileName;
  if ($self->{tempFileName}) {
    $tempFile = $self->{tempFile};
    $tempFileName = $self->{tempFileName};
  }
  else {
    ($tempFile, $tempFileName) = File::Temp::tempfile();
    binmode $tempFile;
    $self->{tempFile} = $tempFile;
    $self->{tempFileName} = $tempFileName;
  }
  
  my $frgs = $self->{frgs};
  my $onMemory = \$self->{onMemory};
  my $length = \$self->{length};
  my $segment = \$self->{segment};
	
  my $frg = $frgs->[$id];
  my $written = $frg->write($tempFile, $onMemory, $segment, $data);
  if (!defined($written)) {close($tempFile); unlink($tempFileName); return undef;}
  $$length += $written;
}

sub close_block ($$) {
  my ($self, $id) = @_;
  # NOP
}

sub serial_write ($$) {
  my ($self, $data) = @_;
  
  my $length = \$self->{length};
  $$length += length($data);
  if ($self->{header}) {
  	$self->{header} = 0;
  	print "\n";
  }
  
  my $out = $self->{OUT};
  print $out $data;
}

sub finish ($) {
  my ($self) = @_;
  my $out = $self->{OUT};
  my $tempFile = $self->{tempFile};
  my $tempFileName = $self->{tempFileName};
  my $first = $self->{first};
  
  if ($self->{header}) {
  	print "Content-Length: ".$self->{length}."\n\n";
  }
  
  my $saveout = select($out);
  $| = 1;
  $| = 0;
  select($saveout);
    
  open($tempFile, "<$tempFileName");
  binmode $tempFile;
  
  my $frg = $first;
  while (defined($frg)) {
    if (!defined($frg->flush($tempFile, $out))) {close($tempFile); unlink($tempFileName); return undef;}
    $frg = $frg->{next};
  }
  close($tempFile);
  unlink($tempFileName);
}

sub dispose ($) {
  my ($self) = @_;
  if ($self->{tempFileName}) {
    my $tempFile = $self->{tempFile};
    my $tempFileName = $self->{tempFileName};
    close($tempFile);
    unlink($tempFileName);
    $self->{tempFile} = undef;
    $self->{tempFileName} = undef;
  }
  $self->{frgs} => [ ];
  $self->{first} => undef;
  $self->{last} => undef;
  $self->{onMemory} => 0;
  $self->{length} => 0;
  $self->{segment} => 0;
  $self->{header} => 0;
}
