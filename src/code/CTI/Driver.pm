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
    $fp = new IO::Socket::SSL("$host:$port");
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

