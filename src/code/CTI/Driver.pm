=head1 NAME

CTI::Driver - CTI ドライバ

=head2 概要

CTI ドライバです。

=head2 作者

$Date: 2011-10-24 20:57:35 +0900 (2011年10月24日 (月)) $ MIYABE Tatsuhiko

=cut
package CTI::Driver;
use CTI::Session;

require Exporter;
@ISA	= qw(Exporter);
@EXPORT_OK	= qw(create_driver_for);

use strict;
use IO::Socket;
use Socket qw(IPPROTO_TCP TCP_NODELAY);

=head1 CTI::Driver

C<new CTI::Driver>

ドライバのコンストラクタです。

ドライバの作成は通常CTI::Driver::create_driverで行うため、
ユーザーがコンストラクタを直接呼び出す必要はありません。

=cut
sub new {
  my $class = shift;
  my $self = {};
  
  bless $self, $class;
  return $self;
}

=head1 CTI::Driver->get_session

C<get_session URI [OPTIONS]>

指定されたURIに接続し、セッションを返します。

=head2 パラメータ

=over

=item URI

	接続先アドレス

=item OPTIONS

	接続オプション

=back

=head2 戻り値

B<CTI::Session,エラーの場合はundef>

=cut
sub get_session ($$;%) {
  my ( $self, $uri, %opts ) = @_;

  my $ssl = 0;
  my $host = 'localhost';
  my $port = 8099;
  if ($uri =~ /^ctips:\/\/([^:\/]+):([0-9]+)\/?$/) {
    $host = $1;
    $port = $2;
    $ssl = 1;
  }
  elsif ($uri =~ /^ctips:\/\/([^:\/]+)\/?$/) {
    $host = $1;
    $ssl = 1;
  }
  elsif ($uri =~ /^ctip:\/\/([^:\/]+):([0-9]+)\/?$/) {
    $host = $1;
    $port = $2;
  }
  elsif ($uri =~ /^ctip:\/\/([^:\/]+)\/?$/) {
    $host = $1;
  }
  
  my $fp; 
  if ($ssl) {
    require IO::Socket::SSL;
    # IO::Socket::SSL は既定でサーバー証明書とホスト名を検証し、SNI を送る。
    # 試験用の逃げ道: insecure => 1 で検証を省く(本番では使わない。相手が誰かを
    # 確かめないまま話すことになる。Java --insecure / .NET ?insecure=1 /
    # Node.js rejectUnauthorized:0 / Ruby 'insecure' に相当。2026-09-20)
    my %ssl_opts = (PeerHost => $host, PeerPort => $port);
    $ssl_opts{SSL_verify_mode} = IO::Socket::SSL::SSL_VERIFY_NONE()
      if $opts{insecure} && $opts{insecure} ne '0' && lc($opts{insecure}) ne 'false';
    $fp = IO::Socket::SSL->new(%ssl_opts);
    # 失敗を黙って undef にしない。以前は new の戻り値を見ずに Session を作り、
    # 証明書の検証に落ちても「Can't call method on an undefined value」で
    # 後から落ちるだけだった(2026-09-20 に 3.2 の TLS 待受で実測)
    unless ($fp) {
      warn('TLS connection failure: ' . ($IO::Socket::SSL::SSL_ERROR || $!));
      return undef;
    }
  }
  else {
    my $address = inet_aton($host);
    my $port_address = sockaddr_in($port, $address);
    my $protocol = getprotobyname('tcp');
    socket($fp, PF_INET, SOCK_STREAM, $protocol) or (warn('Socket error.') and return undef);
    connect($fp, $port_address) or (warn('Connection failure.') and return undef);
    setsockopt($fp, IPPROTO_TCP, TCP_NODELAY, 1);
  }

  return new CTI::Session($fp, %opts);
}

