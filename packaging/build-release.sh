#!/usr/bin/env bash
#
# Build AIM release artifacts for Linux x86_64: .deb, .rpm and .tar.gz.
#
# The GUI (Flutter desktop bundle) installs to /opt/aim and is launched from the
# application menu via the .desktop entry. The gh-style CLI is compiled to a
# standalone binary installed at /usr/bin/aim, so `aim <command>` works in a
# terminal. Both share ~/AppImages and metadata at runtime.
#
# Usage:  packaging/build-release.sh [version]
#         (version defaults to the value in pubspec.yaml)
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKG="$ROOT/packaging"
DIST="$ROOT/dist"

# --- version -----------------------------------------------------------------
VERSION="${1:-}"
if [ -z "$VERSION" ]; then
    VERSION="$(grep -E '^version:' "$ROOT/pubspec.yaml" | awk '{print $2}' | cut -d'+' -f1)"
fi
echo ">> Building AIM $VERSION"

DEB_ARCH="amd64"
RPM_ARCH="x86_64"
MAINTAINER="AzarAI <azaraitop@gmail.com>"
HOMEPAGE="https://github.com/AzarAI-TOP/AIM"
SUMMARY="Advanced AppImage Manager"
DESC_LONG="Manage AppImage applications on Linux with a graphical interface and a gh-style command-line interface."

# --- clean -------------------------------------------------------------------
rm -rf "$DIST"
STAGING="$DIST/staging"
mkdir -p "$STAGING" "$DIST"

# --- build GUI bundle --------------------------------------------------------
echo ">> flutter build linux --release"
( cd "$ROOT" && flutter build linux --release >/dev/null )
BUNDLE="$ROOT/build/linux/x64/release/bundle"
[ -x "$BUNDLE/aim" ] || { echo "!! GUI bundle not found at $BUNDLE"; exit 1; }

# --- compile CLI -------------------------------------------------------------
echo ">> dart compile exe bin/aim.dart"
( cd "$ROOT" && dart compile exe bin/aim.dart -o "$DIST/aim-cli" >/dev/null )

# --- stage FHS tree ----------------------------------------------------------
echo ">> staging FHS tree"
install -d "$STAGING/opt/aim"
cp -a "$BUNDLE/." "$STAGING/opt/aim/"
install -d "$STAGING/usr/bin"
install -m 0755 "$DIST/aim-cli" "$STAGING/usr/bin/aim"
install -D -m 0644 "$PKG/aim.desktop" "$STAGING/usr/share/applications/aim.desktop"
install -D -m 0644 "$PKG/aim.svg" "$STAGING/usr/share/icons/hicolor/scalable/apps/aim.svg"
install -D -m 0644 "$ROOT/README.md" "$STAGING/usr/share/doc/aim/README.md"
chmod 0755 "$STAGING/opt/aim/aim"

# =============================================================================
# tar.gz  (portable archive with install.sh / uninstall.sh)
# =============================================================================
echo ">> tar.gz"
TARNAME="aim-$VERSION-linux-$RPM_ARCH"
TARDIR="$DIST/tar/$TARNAME"
mkdir -p "$TARDIR"
cp -a "$STAGING/opt" "$STAGING/usr" "$TARDIR/"

cat > "$TARDIR/install.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"
DIR="$(cd "$(dirname "$0")" && pwd)"
$SUDO cp -a "$DIR/opt/." /opt/
$SUDO cp -a "$DIR/usr/." /usr/
command -v update-desktop-database >/dev/null 2>&1 && $SUDO update-desktop-database -q /usr/share/applications 2>/dev/null || true
command -v gtk-update-icon-cache  >/dev/null 2>&1 && $SUDO gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor 2>/dev/null || true
echo "AIM installed. Launch from your app menu, or run 'aim --help' in a terminal."
EOS

cat > "$TARDIR/uninstall.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"
$SUDO rm -rf /opt/aim
$SUDO rm -f /usr/bin/aim /usr/share/applications/aim.desktop \
           /usr/share/icons/hicolor/scalable/apps/aim.svg
echo "AIM uninstalled."
EOS
chmod 0755 "$TARDIR/install.sh" "$TARDIR/uninstall.sh"
tar czf "$DIST/$TARNAME.tar.gz" -C "$DIST/tar" "$TARNAME"

# =============================================================================
# .deb  (dpkg-deb if available, otherwise hand-built with ar)
# =============================================================================
echo ">> .deb"
DEB_FILE="$DIST/aim_${VERSION}_${DEB_ARCH}.deb"
INSTALLED_KB="$(du -ks "$STAGING" | cut -f1)"
DEBROOT="$DIST/deb"
mkdir -p "$DEBROOT/DEBIAN"
cp -a "$STAGING/opt" "$STAGING/usr" "$DEBROOT/"
cat > "$DEBROOT/DEBIAN/control" <<EOF
Package: aim
Version: $VERSION
Architecture: $DEB_ARCH
Maintainer: $MAINTAINER
Installed-Size: $INSTALLED_KB
Depends: libgtk-3-0
Section: utils
Priority: optional
Homepage: $HOMEPAGE
Description: $SUMMARY
 $DESC_LONG
EOF
install -m 0755 "$PKG/scripts/after-install.sh" "$DEBROOT/DEBIAN/postinst"
install -m 0755 "$PKG/scripts/after-remove.sh" "$DEBROOT/DEBIAN/postrm"

if command -v dpkg-deb >/dev/null 2>&1; then
    dpkg-deb --build --root-owner-group "$DEBROOT" "$DEB_FILE" >/dev/null
else
    echo "   (dpkg-deb missing — assembling .deb with ar)"
    WORK="$DIST/deb-work"
    mkdir -p "$WORK"
    echo "2.0" > "$WORK/debian-binary"
    # control.tar.gz
    ( cd "$DEBROOT/DEBIAN" && tar --owner=0 --group=0 -czf "$WORK/control.tar.gz" ./* )
    # data.tar.gz
    ( cd "$DEBROOT" && tar --owner=0 --group=0 --exclude=./DEBIAN -czf "$WORK/data.tar.gz" ./opt ./usr )
    ( cd "$WORK" && ar rc "$DEB_FILE" debian-binary control.tar.gz data.tar.gz )
fi

# =============================================================================
# .rpm  (rpmbuild)
# =============================================================================
if command -v rpmbuild >/dev/null 2>&1; then
    echo ">> .rpm"
    RPMTOP="$DIST/rpmbuild"
    mkdir -p "$RPMTOP"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS}
    cp -a "$STAGING" "$RPMTOP/SOURCES/staging"
    SPEC="$RPMTOP/SPECS/aim.spec"
    cat > "$SPEC" <<EOF
%global debug_package %{nil}
%global __os_install_post %{nil}

Name:           aim
Version:        $VERSION
Release:        1%{?dist}
Summary:        $SUMMARY
License:        MIT
URL:            $HOMEPAGE
BuildArch:      $RPM_ARCH
Requires:       gtk3
AutoReqProv:    no

%description
$DESC_LONG

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}
cp -a %{_sourcedir}/staging/. %{buildroot}/

%post
if command -v update-desktop-database >/dev/null 2>&1; then update-desktop-database -q /usr/share/applications || true; fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor || true; fi

%postun
if command -v update-desktop-database >/dev/null 2>&1; then update-desktop-database -q /usr/share/applications || true; fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor || true; fi

%files
/opt/aim
/usr/bin/aim
/usr/share/applications/aim.desktop
/usr/share/icons/hicolor/scalable/apps/aim.svg
/usr/share/doc/aim/README.md
EOF
    rpmbuild --define "_topdir $RPMTOP" -bb "$SPEC" >/dev/null
    cp "$RPMTOP"/RPMS/$RPM_ARCH/aim-"$VERSION"-1.*.rpm "$DIST/" 2>/dev/null || \
        cp "$RPMTOP"/RPMS/*/aim-"$VERSION"-1.*.rpm "$DIST/"
else
    echo "!! rpmbuild not found — skipping .rpm"
fi

# --- summary -----------------------------------------------------------------
echo ""
echo ">> Artifacts:"
( cd "$DIST" && ls -1 *.deb *.rpm *.tar.gz 2>/dev/null )
