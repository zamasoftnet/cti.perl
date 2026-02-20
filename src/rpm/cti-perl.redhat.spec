%define perl_vendorlib /usr/share/perl5/vendor_perl

Name:			cti-perl
Version:		@version.number@
Release:		0
Epoch:			@build.number@
Group:			Publishing
Summary:		Copper PDF Perl driver
Source0:		cti-perl-@aversion.number@.tar.gz
Requires:		perl(IO::Socket), perl(File::Temp)
BuildRoot:		%{_tmppath}/%{name}-%{version}-%{release}-buildroot
Vendor:			Zamasoft
License:		Commercial
URL:			http://copper-pdf.com/
Packager:		MIYABE Tatsuhiko
ExclusiveOS:	linux

%description
cti-perl-@version.number@

%prep
rm -rf $RPM_BUILD_ROOT/*
mkdir -p $RPM_BUILD_ROOT%{perl_vendorlib}

%setup

%build

%install
cp -pr code/CTI $RPM_BUILD_ROOT%{perl_vendorlib}/

%pre

%post

%preun

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-, root, root, 0755)
%{perl_vendorlib}/CTI
