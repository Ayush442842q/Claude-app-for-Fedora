%global debug_package %{nil}

Name:           claude-desktop
Version:        %{?app_version}%{!?app_version:0.0.0}
Release:        1%{?dist}
Summary:        Claude Desktop, repackaged for Fedora/RPM-based distros

License:        Proprietary
URL:            https://claude.ai/download
# Source0 is staged by build-rpm.sh before rpmbuild runs; it is not a
# plain upstream tarball, so it isn't listed here as a download URL.
Source0:        claude-desktop-payload.tar.gz

BuildArch:      x86_64

Requires:       gtk3
Requires:       nss
Requires:       alsa-lib
Requires:       libnotify
Requires:       libXScrnSaver
Requires:       libXtst
Requires:       at-spi2-core
Requires:       libsecret
Requires:       mesa-libgbm

%description
Unofficial repackaging of Anthropic's official Claude Desktop application
(originally distributed as a .deb for Debian/Ubuntu) into an RPM for
Fedora and other RPM-based distributions.

This is a community packaging project, not affiliated with or endorsed
by Anthropic. The bundled application and its assets remain the property
of Anthropic under Anthropic's own terms; only the packaging scripts in
this project are separately licensed (see LICENSE).

%prep
%setup -q -c -n %{name}-%{version}

%build
# Nothing to build: the Electron app is used as extracted from upstream.

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/usr/lib/claude-desktop
mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/usr/share/applications
mkdir -p %{buildroot}/usr/share/icons/hicolor

cp -a app/. %{buildroot}/usr/lib/claude-desktop/

install -Dm644 claude-desktop.desktop \
    %{buildroot}/usr/share/applications/claude-desktop.desktop

if [ -d icons/hicolor ]; then
    cp -a icons/hicolor/. %{buildroot}/usr/share/icons/hicolor/
fi

install -Dm755 claude-desktop.sh %{buildroot}/usr/bin/claude-desktop

%files
/usr/lib/claude-desktop
/usr/bin/claude-desktop
/usr/share/applications/claude-desktop.desktop
/usr/share/icons/hicolor

%changelog
* Thu Jan 01 1970 packager <packager@localhost> - 0.0.0-1
- Initial spec scaffold; version is injected at build time by build-rpm.sh
