use strict;
use warnings;
use ExtUtils::MakeMaker;

# src/code/ 以下の全 .pm ファイルを INST_LIB へマッピングする
my %pm_files;
for my $file (glob('src/code/CTI.pm'),
              glob('src/code/CTI/*.pm'),
              glob('src/code/CTI/*/*.pm'),
              glob('src/code/CTI/*/*/*.pm')) {
    (my $dst = $file) =~ s{^src/code/}{};
    $pm_files{$file} = '$(INST_LIB)/' . $dst;
}

WriteMakefile(
    NAME             => 'CTI',
    AUTHOR           => 'Zamasoft <info@zamasoft.jp>',
    VERSION          => '2.1.4',
    ABSTRACT         => 'CTI driver for Copper PDF server',
    LICENSE          => 'apache_2_0',
    MIN_PERL_VERSION => '5.006001',
    PREREQ_PM => {
        'File::Temp'       => 0,
        'IO::Socket::INET' => 0,
    },
    PM => \%pm_files,
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/zamasoftnet/cti.perl.git',
                web  => 'https://github.com/zamasoftnet/cti.perl',
            },
            license => ['http://www.apache.org/licenses/LICENSE-2.0'],
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES => 'CTI-*' },
);
