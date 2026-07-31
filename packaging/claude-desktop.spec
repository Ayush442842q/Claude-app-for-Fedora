%global debug_package %{nil}

Name:           claude-desktop
Version:        %{?app_version}%{!?app_version:0.0.0}
Release:        %{?app_release}%{!?app_release:1}%{?dist}
Summary:        Claude Desktop, repackaged for Fedora/RPM-based distros

License:        Proprietary
URL:            https://claude.ai
# Source0 is staged by build-rpm.sh before rpmbuild runs; it is not a
# plain upstream tarball, so it isn't listed here as a download URL.
Source0:        claude-desktop-payload.tar.gz

BuildArch:      %{?app_rpm_arch}%{!?app_rpm_arch:x86_64}

# Mirrors the upstream .deb's Depends: field, mapped to Fedora package
# names via scripts/map-deps.sh. Update both if upstream's deps change.
Requires:       gtk3
Requires:       libnotify
Requires:       nss
Requires:       xdg-utils
Requires:       at-spi2-core
Requires:       libdrm
Requires:       mesa-libgbm
Requires:       libxcb
Requires:       libsecret
Requires:       gvfs
Requires:       libXtst
Requires:       libuuid
Requires:       xdg-desktop-portal
Requires:       xdg-desktop-portal-gtk

# Mirrors the upstream .deb's Recommends: field.
Recommends:     alsa-lib
Recommends:     pulseaudio
Recommends:     libappindicator-gtk3
Recommends:     ca-certificates
Recommends:     gnome-keyring

%description
Unofficial repackaging of Anthropic's official Claude Desktop application
(originally distributed as a .deb for Debian/Ubuntu) into an RPM for
Fedora and other RPM-based distributions.

This is a community packaging project, not affiliated with or endorsed
by Anthropic. The bundled application and its assets remain the property
of Anthropic under Anthropic's own terms; only the packaging scripts in
this project are separately licensed (see LICENSE).

%prep
# Source0 already has a top-level claude-desktop-%{version}/ directory
# matching %{name}-%{version}, so a plain %setup is correct here; -c
# would extract it a second level too deep.
%setup -q

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

ln -sf ../lib/claude-desktop/claude-desktop %{buildroot}/usr/bin/claude-desktop

%files
# chrome-sandbox needs the setuid bit to run Chromium's SUID sandbox;
# upstream's .deb ships it 4755, but plain (non-root) tar/ar extraction
# drops that bit, so it's restored explicitly here regardless of which
# user ran the packaging steps. (rpm warns "File listed twice" because
# it's also covered by the directory entry below — harmless, the more
# specific %attr line wins.)
%attr(4755,root,root) /usr/lib/claude-desktop/chrome-sandbox
/usr/lib/claude-desktop
/usr/bin/claude-desktop
/usr/share/applications/claude-desktop.desktop
/usr/share/icons/hicolor

%changelog

