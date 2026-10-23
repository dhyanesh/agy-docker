#!/usr/bin/env bash
# package-deb.sh: Build a Debian (.deb) package for agy-docker

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="${1:-1.0.0}"
PKG_NAME="agy-docker"
ARCH="all"
DIST_DIR="${SCRIPT_DIR}/dist"
DEB_FILE="${DIST_DIR}/${PKG_NAME}_${VERSION}_${ARCH}.deb"
TAR_FILE="${DIST_DIR}/${PKG_NAME}_${VERSION}.tar.gz"

echo "📦 Packaging ${PKG_NAME} v${VERSION} (${ARCH})..."

mkdir -p "${DIST_DIR}"

# Create temporary build staging directory
BUILD_DIR="$(mktemp -d -t agy-docker-deb-XXXXXX)"
trap 'rm -rf "${BUILD_DIR}"' EXIT
chmod 755 "${BUILD_DIR}"

# Create directory hierarchy
mkdir -p "${BUILD_DIR}/DEBIAN"
mkdir -p "${BUILD_DIR}/usr/bin"
mkdir -p "${BUILD_DIR}/usr/share/${PKG_NAME}"
mkdir -p "${BUILD_DIR}/usr/share/doc/${PKG_NAME}"

# Control file
cat > "${BUILD_DIR}/DEBIAN/control" <<EOF
Package: ${PKG_NAME}
Version: ${VERSION}
Section: devel
Priority: optional
Architecture: ${ARCH}
Depends: bash, docker-ce | docker.io, coreutils
Recommends: sudo
Maintainer: Dhyanesh Damania <d2githubfake@fake.com>
Homepage: https://github.com/dhyanesh/agy-docker
Description: Run Google Antigravity CLI (agy) autonomously inside Docker containers
 agy-docker wraps the Google Antigravity CLI (agy) to run autonomous coding
 sessions inside isolated Docker containers per project. Includes automated
 OAuth token refresh, host binary passthrough, and secondary storage utilities.
EOF

# Post-installation script (informative reminder)
cat > "${BUILD_DIR}/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
if [ "$1" = "configure" ]; then
    echo "=========================================================="
    echo "🐳 agy-docker v${VERSION} installed successfully!"
    echo "   • Run 'agy-docker --build' to initialize the base image"
    echo "   • Run 'setup-docker-storage' to configure storage disks"
    echo "=========================================================="
fi
exit 0
EOF
chmod 755 "${BUILD_DIR}/DEBIAN/postinst"

# Install binaries into /usr/bin
cp "${SCRIPT_DIR}/agy-docker" "${BUILD_DIR}/usr/bin/agy-docker"
cp "${SCRIPT_DIR}/setup-docker-storage.sh" "${BUILD_DIR}/usr/bin/setup-docker-storage"
chmod 755 "${BUILD_DIR}/usr/bin/agy-docker"
chmod 755 "${BUILD_DIR}/usr/bin/setup-docker-storage"

# Install package shared files into /usr/share/agy-docker
cp "${SCRIPT_DIR}/Dockerfile" "${BUILD_DIR}/usr/share/${PKG_NAME}/Dockerfile"
cp "${SCRIPT_DIR}/build.sh" "${BUILD_DIR}/usr/share/${PKG_NAME}/build.sh"
cp "${SCRIPT_DIR}/setup-docker-storage.sh" "${BUILD_DIR}/usr/share/${PKG_NAME}/setup-docker-storage.sh"
chmod 644 "${BUILD_DIR}/usr/share/${PKG_NAME}/Dockerfile"
chmod 755 "${BUILD_DIR}/usr/share/${PKG_NAME}/build.sh"
chmod 755 "${BUILD_DIR}/usr/share/${PKG_NAME}/setup-docker-storage.sh"

# Install documentation
cp "${SCRIPT_DIR}/README.md" "${BUILD_DIR}/usr/share/doc/${PKG_NAME}/README.md"
cat > "${BUILD_DIR}/usr/share/doc/${PKG_NAME}/copyright" <<EOF
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: agy-docker
Source: https://github.com/dhyanesh/agy-docker

Files: *
Copyright: $(date +%Y) Dhyanesh Damania
License: Apache-2.0
EOF
chmod 644 "${BUILD_DIR}/usr/share/doc/${PKG_NAME}/"*

# Build the .deb package
echo "🔨 Generating ${DEB_FILE}..."
dpkg-deb --build --root-owner-group "${BUILD_DIR}" "${DEB_FILE}"

# Also generate a standalone source tarball
echo "📦 Generating source tarball ${TAR_FILE}..."
tar --exclude="./dist" --exclude="./.git" -czf "${TAR_FILE}" -C "${SCRIPT_DIR}" .

# Generate checksums
(cd "${DIST_DIR}" && sha256sum "$(basename "${DEB_FILE}")" "$(basename "${TAR_FILE}")" > SHA256SUMS)

echo "──────────────────────────────────────────────────────────"
echo "✅ Package created successfully:"
echo "   DEB:      ${DEB_FILE}"
echo "   Tarball:  ${TAR_FILE}"
echo "   SHA256:   ${DIST_DIR}/SHA256SUMS"
cat "${DIST_DIR}/SHA256SUMS"
echo "──────────────────────────────────────────────────────────"
