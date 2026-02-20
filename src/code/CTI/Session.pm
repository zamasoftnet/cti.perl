=head1 NAME

CTI::Session - セッション

=head2 概要

文書変換を実行するためのセッションです。

=head2 作者

$Date: 2011-01-20 20:01:03 +0900 (2011年01月20日 (木)) $ MIYABE Tatsuhiko

=cut
package CTI::Session;

require Exporter;
@ISA	= qw(Exporter);

use strict;
use Symbol;
use CTI::CTIP2::CTIP;
use CTI::Results::SingleResult;
use CTI::Results::DirectoryResults;
use CTI::Builder::StreamBuilder;
use CTI::Builder::FileBuilder;
use CTI::CTIP2::ResourceOutputTie;
use CTI::CTIP2::MainOutputTie;

=head1 CTI::Session

C<new CTI::Session IOHANDLE HOST PORT [OPTIONS]>

セッションのコンストラクタです。

セッションの作成は通常CTI::Driver::create_sessionで行うため、
ユーザーがコンストラクタを直接呼び出す必要はありません。

=head2 引数

=over

=item IOHANDLE

	入出力ストリーム(通常はソケット)

=item OPTIONS

	接続オプション

=back

=cut
sub new ($*;%) {
  my ( $class, $fp, %opts ) = @_;
  
  my $user = $opts{user};
  my $password = $opts{password};
  my $encoding = 'UTF-8';
  if ($opts{encoding}) {
  	$encoding = $opts{encoding};
  }
  CTI::CTIP2::CTIP::connect($fp, $encoding) or return undef;
  CTI::Helpers::write($fp, "PLAIN: $user $password\n") or return undef;
  my $response = CTI::Helpers::read($fp, 4);
  $response eq "OK \n" or (warn('Authentication failed') and return undef);

  my $self = {
    'state' => 1,
    'FP' => $fp,
    'results' => CTI::Results::SingleResult->new(CTI::Builder::StreamBuilder->new(*STDOUT)),
    'message_func' => undef,
    'progress_func' => undef,
    'resolver_func' => undef,
    'main_length' => undef,
    'main_read' => undef,
  };
  
  bless $self, $class;
  return $self;
}

=head1 CTI::Session->get_server_info

C<get_server_info URI>

サーバー情報を返します。

詳細は以下をご覧下さい。

L<http://sourceforge.jp/projects/copper/wiki/CTIP2.0%E3%81%AE%E3%82%B5%E3%83%BC%E3%83%90%E3%83%BC%E6%83%85%E5%A0%B1>

=head2 引数

=over

=item URI

	サーバー情報のURI

=back

=head2 戻り値

B<サーバー情報のデータ,失敗ならundef>

=cut
sub get_server_info ($$) {
  my ($self, $uri) = @_;
  defined CTI::CTIP2::CTIP::req_server_info($self->{FP}, $uri) or return undef;
  my $data = '';
  for (my %next = CTI::CTIP2::CTIP::res_next($self->{FP}); $next{type} != CTI::CTIP2::CTIP::RES_EOF; %next = CTI::CTIP2::CTIP::res_next($self->{FP})) {
  	$data .= $next{bytes};
  }
  return $data;
}

=head1 CTI::Session->set_results

C<set_results RESULTS>

変換結果の出力先を指定します。

transcodeおよびstart_mainの前に呼び出してください。
この関数を呼び出さない場合、出力先はCTI::Results::SingleResult->new(CTI::Builder::StreamBuilder->new(*STDOUT)になります。

=head2 引数

=over

=item RESULTS

	出力先 Results。

=back

=cut
sub set_results ($$) {
  my ($self, $results) = @_;
  
  if ($self->{state} >= 2) {
    warn ('Main content was already sent');
    return undef;
  }
  $self->{results} = $results;
}

=head1 CTI::Session->set_output_as_handle

C<set_output_as_handle OUTPUTHANDLE>

変換結果の出力先ファイルハンドルを指定します。

set_resultsの簡易版です。
こちらは、１つだけ結果を出力するファイルハンドルを直接設定出来ます。

=head2 引数

=over

=item OUTPUTHANDLE

	出力先ハンドル。

=item HEADER

	1ならContent-Type, Content-Lengthヘッダを出力する。

=back

=cut
sub set_output_as_handle ($*;$) {
  my ($self, $out, $header) = @_;
  $out = Symbol::qualify_to_ref($out, caller);
  
  $self->set_results(CTI::Results::SingleResult->new(CTI::Builder::StreamBuilder->new($out), $header));
}

=head1 CTI::Session->set_output_as_file

C<>set_output_as_file FILENAME>

変換結果の出力先ファイル名を指定します。

set_resultsの簡易版です。
こちらは、１つだけ結果を出力するファイル名を直接設定出来ます。

=head2 引数

=over

=item FILENAME

	出力先ファイル名。

=back

=cut
sub set_output_as_file ($$) {
  my ($self, $file) = @_;
  
  $self->set_results(CTI::Results::SingleResult->new(CTI::Builder::FileBuilder->new($file)));
}

=head1 CTI::Session->set_output_as_directory

C<set_output_as_directory DIRNAME PREFIX SUFFIX>

変換結果の出力先ディレクトリ名を指定します。

set_resultsの簡易版です。
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
sub set_output_as_directory ($$;$$) {
  my ($self, $dir, $prefix, $suffix) = @_;
  
  $self->set_results(CTI::Results::DirectoryResults->new($dir, $prefix, $suffix));
}

=head1 CTI::Session->set_message_func

C<set_message_func FUNCTION>

メッセージ受信のためのコールバック関数を設定します。

transcodeおよびstart_mainの前に呼び出してください。
コールバック関数の引数は、メッセージコード(int)、メッセージ(string)、引数(array)です。

=head2 引数

=over

=item FUNCTION

	コールバック関数

=back

=cut
sub set_message_func ($&) {
  my ($self, $message_func) = @_;
  
  if ($self->{state} >= 2) {
    warn ('Main content was already sent');
    return undef;
  }
  $self->{message_func} = $message_func;
}

=head1 CTI::Session->set_progress_func

C<set_progress_func FUNCTION>

進行状況受信のためのコールバック関数を設定します。

transcodeおよびstart_mainの前に呼び出してください。
コールバック関数の引数は、変換前文書のサイズ(integer)、読み込み済みバイト数(integer)です。

=head2 引数

=over

=item FUNCTION

	コールバック関数

=back

=cut
sub set_progress_func ($&) {
  my ($self, $progress_func) = @_;
 
  if ($self->{state} >= 2) {
    warn ('Main content is already sent');
    return undef;
  }
  $self->{progress_func} = $progress_func;
}

=head1 CTI::Session->set_resolver_func

C<set_resolver_func FUNCTION>

リソース解決のためのコールバック関数を設定します。

transcodeおよびstart_mainの前に呼び出してください。
コールバック関数の引数は、URI(string)と、リソースをサーバーに送るための、さらなるコールバック関数(function)です。

さらなるコールバック関数はURI(string)とOPTIONS(hash)を引数とし、出力先のファイルハンドルを返します。

=head2 引数

=over

=item FUNCTION

	コールバック関数

=back

=cut
sub set_resolver_func ($&) {
  my ($self, $resolver_func) = @_;
 
  if ($self->{state} >= 2) {
    warn ('Main content is already sent');
    return undef;
  }
  $self->{resolver_func} = $resolver_func;
  CTI::CTIP2::CTIP::req_client_resource($self->{FP}, $resolver_func ? 1 : 0);
}

=head1 CTI::Session->set_continuous

C<set_continuous MODE>

複数の結果を結合するモードを切り替えます。
モードが有効な場合、join()の呼び出しで複数の結果を結合して返します。

transcodeおよびstart_mainの前に呼び出してください。

=head2 引数

=over

=item MODE

	有効にするにはTRUE

=back

=cut
sub set_continuous ($&) {
  my ($self, $mode) = @_;
 
  if ($self->{state} >= 2) {
    warn ('Main content is already sent');
    return undef;
  }
  CTI::CTIP2::CTIP::req_continuous($self->{FP}, $mode ? 1 : 0);
}

=head1 CTI::Session->property

C<property NAME VALUE>

プロパティを設定します。

セッションを作成した直後に呼び出してください。
利用可能なプロパティの一覧は「開発者ガイド」を参照してください。

=head2 引数

=over

=item NAME

	名前

=item VALUE

	値

=back

=head2 戻り値

B<成功なら1,失敗ならundef>

=cut
sub property ($$$) {
  my ($self, $name, $value) = @_;
  
  if ($self->{state} >= 2) {
    warn ('Main content was already sent');
    return undef;
  }
  return CTI::CTIP2::CTIP::req_property($self->{FP}, $name, $value);
}

=head1 CTI::Session->transcode

C<transcode URI>

サーバー側文書を変換します。

この関数は1つのセッションにつき1度だけ呼ぶことができます。

=head2 引数

=over

=item URI

	変換対象のURI

=back

=head2 戻り値

B<成功なら1,失敗ならundef>

=cut
sub transcode ($$) {
  my ($self, $uri) = @_;

  if ($self->{state} >= 2) {
    warn ('Main content was already sent');
    return undef;
  }
  CTI::CTIP2::CTIP::req_server_main($self->{FP}, $uri) or return undef;
  $self->{state} = 2;
  while($self->build_next()) {
  	# do nothing
  }
  $self->{state} = 1;
  return 1;
}

=head1 CTI::Session->start_resource

C<start_resource FILEHANDLE URI [OPTIONS]>

クライアント側リソースの送信を開始します。

start_resource,end_resourceは対となります。
これらの関数はformat_mainおよびstart_mainの前に呼び出してください。

指定されたファイルハンドルに書き出されたデータがサーバーに送られます。
ファイルハンドルは新しく作成したものでも、既存のものでも構いません。
例えば、STDOUTを設定すれば、標準出力に書き出したデータがサーバーに送られます。
end_resourceを呼び出すと、ファイルハンドルの状態は元に戻ります。

IGNORE_HEADERに1を設定すると、出力される内容のヘッダ部分を無視します。
データの先頭から、空行までの間がヘッダと認識されます。

=head2 引数

=over

=item FILEHANDLE

	ファイルハンドル

=item URI

	リソースの仮想URI

=item OPTIONS

	オプション mime_type => 'MIME型', encoding => 'キャラクタ・エンコーディイング', length => 予測されるデータサイズ（バイト）, ignore_headers => ヘッダを除去する場合は1

=back

=head2 戻り値

B<成功なら1,失敗ならundef>

=cut
sub start_resource ($*$;%) {
  my ($self, $fp, $uri, %opts) = @_;

  my $mime_type = $opts{mime_type} || 'text/css';
  my $encoding = $opts{encoding} || '';
  my $length = $opts{length} || -1;
  my $ignore_header = $opts{ignore_headers} || $opts{ignore_header} || 0;
  $fp = Symbol::qualify_to_ref($fp, caller);

  if ($self->{state} >= 2) {
    warn ('Main content was already sent');
    return undef;
  }
  if ($ignore_header) {
  	$ignore_header = 1;
  }
  CTI::CTIP2::CTIP::req_resource($self->{FP}, $uri, $mime_type, $encoding, $length) or return undef;
  tie(*$fp, 'CTI::CTIP2::ResourceOutputTie', $self->{FP}, $ignore_header);
  return 1;
}

=head1 CTI::Session->end_resource

C<end_resource FILEHANDLE>

リソースの送信を終了し、ファイルハンドルの状態を復帰します。

start_resource,end_resourceは対となります。
これらの関数はformat_mainおよびstart_mainの前に呼び出してください。

=head2 引数

=over

=item FILEHANDLE

	ファイルハンドル

=back

=head2 戻り値

B<成功なら1,失敗ならundef>

=cut
sub end_resource ($*) {
  my ($self, $fp) = @_;
  $fp = Symbol::qualify_to_ref($fp, caller());
  
  close($fp);
  untie(*$fp);
  CTI::CTIP2::CTIP::req_eof($self->{FP});
  return 1;
}

=head1 CTI::Session->start_main

C<start_main FILEHANDLE URI [OPTIONS]>

クライアント側の本体の送信を開始します。

start_main,end_mainは対となります。
本体の送信は1つのセッションにつき1度だけです。

指定されたファイルハンドルに書き出されたデータがサーバーに送られます。
ファイルハンドルは新しく作成したものでも、既存のものでも構いません。
例えば、STDOUTを設定すれば、標準出力に書き出したデータがサーバーに送られます。
end_mainを呼び出すと、ファイルハンドルの状態は元に戻ります。

IGNORE_HEADERに1を設定すると、出力される内容のヘッダ部分を無視します。
データの先頭から、空行までの間がヘッダと認識されます。

=head2 引数

=over

=item FILEHANDLE

	ファイルハンドル

=item URI

	リソースの仮想URI

=item OPTIONS

	オプション mime_type => 'MIME型', encoding => 'キャラクタ・エンコーディイング', length => 予測されるデータサイズ（バイト）, ignore_headers => ヘッダを除去する場合は1

=back

=head2 戻り値

B<成功なら1,失敗ならundef>

=cut
sub start_main ($*$;%) {
  my ($self, $fp, $uri, %opts) = @_;

  my $mime_type = $opts{mime_type} || '';
  my $encoding = $opts{encoding} || '';
  my $length = $opts{length} || -1;
  my $ignore_header = $opts{ignore_headers} || $opts{ignore_header} || 0;
  $fp = Symbol::qualify_to_ref($fp, caller);

  if ($self->{state} >= 2) {
    warn ('Main content was already sent');
    return undef;
  }
  $self->{state} = 2;
  if ($ignore_header) {
  	$ignore_header = 1;
  }
  CTI::CTIP2::CTIP::req_start_main($self->{FP}, $uri, $mime_type, $encoding, $length) or return undef;
  tie(*$fp, 'CTI::CTIP2::MainOutputTie', $self->{FP}, $self, $ignore_header);
}

=head1 CTI::Session->end_main

C<end_main FILEHANDLE>

本体の送信を終了し、ファイルハンドルの状態を復帰します。

start_main,end_mainは対となります。
本体の送信は1つのセッションにつき1度だけです。

=head2 引数

=over

=item FILEHANDLE

	ファイルハンドル

=back

=head2 戻り値

B<成功なら1,失敗ならundef>

=cut
sub end_main ($*) {
  my ($self, $fp) = @_;
  $fp = Symbol::qualify_to_ref($fp, caller());
  
  close($fp);
  untie(*$fp);
  CTI::CTIP2::CTIP::req_eof($self->{FP});
  while($self->build_next()) {
  	# do nothing
  }
  $self->{state} = 1;
  return 1;
}

=head1 CTI::Session->abort

C<abort MODE>

変換処理の中断を要求します。

=head2 引数

=over

=item MODE

	中断モード 0=生成済みのデータを出力して中断, 1=即時中断

=back

=head2 戻り値

B<成功なら1,失敗ならundef>

=cut
sub abort ($$) {
  my ($self, $mode) = @_;
  
  defined(CTI::CTIP2::CTIP::req_abort($self->{FP}, $mode)) or return undef;
}

=head1 CTI::Session->reset

C<reset>

全ての状態をリセットします。

=head2 戻り値

B<成功なら1,失敗ならundef>

=cut
sub reset ($) {
  my ($self) = @_;
  defined(CTI::CTIP2::CTIP::req_reset($self->{FP})) or return undef;
  $self->{progress_func} = undef;
  $self->{message_func} = undef;
  $self->{resolver_func} = undef;
  $self->{results} = CTI::Results::SingleResult->new(CTI::Builder::StreamBuilder->new(*STDOUT));
  $self->{state} = 1;
}

=head1 CTI::Session->join

C<join>

結果を結合します。

=head2 戻り値

B<成功なら1,失敗ならundef>

=cut
sub join ($) {
  my ($self) = @_;
  defined(CTI::CTIP2::CTIP::req_join($self->{FP})) or return undef;
  $self->{state} = 2;
  while($self->build_next()) {
  	# do nothing
  }
}

=head1 CTI::Session->close

C<close>

セッションを閉じます。

この関数の呼出し後、対象となったセッションに対するいかなる操作もできません。

=head2 戻り値

B<成功なら1,失敗ならundef>

=cut
sub close ($) {
  my ($self) = @_;
  
  if ($self->{state} >= 3) {
    warn ('The session is already closed');
    return undef;
  }
  defined(CTI::CTIP2::CTIP::req_close($self->{FP})) or return undef;
  $self->{state} = 3;
  return 1;
}

sub build_next ($) {
  my ($self) = @_;
  
  my %next = CTI::CTIP2::CTIP::res_next($self->{FP});
  if (! %next) {
  	return undef;
  }
  my $type = $next{type};
  # printf "[%X]\n", $type;
  if($type == CTI::CTIP2::CTIP::RES_START_DATA) {
  	if ($self->{builder}) {
  	  $self->{builder}->finish();
  	  $self->{builder}->dispose();
  	  $self->{builder} = undef;
  	}
  	$self->{builder} = $self->{results}->next_builder(%next);
  } elsif($type == CTI::CTIP2::CTIP::RES_BLOCK_DATA) {
  	$self->{builder}->write($next{block_id}, $next{bytes});
  } elsif($type == CTI::CTIP2::CTIP::RES_ADD_BLOCK) {
  	$self->{builder}->add_block();
  } elsif($type == CTI::CTIP2::CTIP::RES_INSERT_BLOCK) {
  	$self->{builder}->insert_block_before($next{block_id});
  } elsif($type == CTI::CTIP2::CTIP::RES_CLOSE_BLOCK) {
  	$self->{builder}->close_block($next{block_id});
  } elsif($type == CTI::CTIP2::CTIP::RES_DATA) {
  	$self->{builder}->serial_write($next{bytes});
  } elsif($type == CTI::CTIP2::CTIP::RES_MESSAGE) {
  	if ($self->{message_func}) {
  	  $self->{message_func}($next{code}, $next{message}, @{$next{args}});
  	}
  } elsif($type == CTI::CTIP2::CTIP::RES_MAIN_LENGTH) {
  	$self->{main_length} = $next{length};
   	if ($self->{progress_func}) {
  	  $self->{progress_func}($self->{main_length}, $self->{main_read});
  	}
  } elsif($type == CTI::CTIP2::CTIP::RES_MAIN_READ) {
  	$self->{main_read} = $next{length};
  	if ($self->{progress_func}) {
  	  $self->{progress_func}($self->{main_length}, $self->{main_read});
  	}
  } elsif($type == CTI::CTIP2::CTIP::RES_RESOURCE_REQUEST) {
  	my $uri = $next{uri};
  	my $missing = 1;
  	if ($self->{resolver_func}) {
  	    my $fp = undef;
  		$self->{resolver_func}($uri, sub {
  			my (%opts) = @_;
		    my $mime_type = $opts{mime_type} || '';
		    my $encoding = $opts{encoding} || '';
		    my $length = $opts{length} || -1;
		    my $ignore_header = $opts{ignore_header} || 0;
            if ($ignore_header) {
             	$ignore_header = 1;
            }
  		    $fp = IO::Handle->new;
            CTI::CTIP2::CTIP::req_resource($self->{FP}, $uri, $mime_type, $encoding, $length) or return undef;
            tie(*$fp, 'CTI::CTIP2::ResourceOutputTie', $self->{FP}, $ignore_header);
  			return $fp;
  		});
   		if ($fp) {
	      close($fp);
	      untie(*$fp);
	      CTI::CTIP2::CTIP::req_eof($self->{FP});
	      $missing = 0;
  		}
  	}
	if ($missing) {
  	  defined(CTI::CTIP2::CTIP::req_missing_resource($self->{FP}, $uri)) or return undef;
  	}
  } elsif($type == CTI::CTIP2::CTIP::RES_ABORT) {
  	if ($self->{builder}) {
  	  if ($next{mode} == 0) {
  	    $self->{builder}->finish();
      }
      $self->{builder}->dispose();
  	  $self->{builder} = undef;
  	}
  	$self->{main_length} = undef;
  	$self->{main_read} = undef;
  	return 0;
  } elsif($type == CTI::CTIP2::CTIP::RES_EOF) {
  	$self->{builder}->finish();
  	$self->{builder}->dispose();
  	$self->{builder} = undef;
  	$self->{main_length} = undef;
  	$self->{main_read} = undef;
  	$self->{state} = 1;
  	return 0;
  } elsif($type == CTI::CTIP2::CTIP::RES_NEXT) {
    $self->{state} = 1;
  	return 0;
  }
  return 1;
}
