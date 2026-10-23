#!/usr/bin/env bash
# setup-docker-storage.sh
#
# Sets up a scalable Docker storage volume on an external mount point (e.g. NTFS, FAT, ext4)
# using a sparse ext4 loopback image. This bypasses non-POSIX/fuseblk filesystem limitations
# and preserves root partition space without requiring repartitioning.
#
# Usage:
#   sudo ./setup-docker-storage.sh <STORAGE_DIR> [SIZE_GB] [TARGET_DIR]
# Or using flags:
#   sudo ./setup-docker-storage.sh -d /mnt/external-drive -s 500
#
# Run with --help for full documentation.

set -euo pipefail

usage() {
    cat <<EOF
Usage: sudo ./setup-docker-storage.sh [OPTIONS] <STORAGE_DIR> [SIZE_GB] [TARGET_DIR]

Arguments:
  STORAGE_DIR           Directory/mount where the disk image will be stored (e.g., /mnt/data)
  SIZE_GB               Maximum virtual disk size in GB (default: 500).
                        Allocated as a sparse file (only consumes physical disk space as used).
  TARGET_DIR            Mount destination for Docker storage (default: /var/lib/docker)

Options:
  -d, --dir DIR         Storage directory (same as STORAGE_DIR)
  -s, --size GB         Maximum capacity in GB (default: 500)
  -t, --target DIR      Mount destination (default: /var/lib/docker)
  -i, --image-name NAME Disk image filename (default: docker-storage.img)
  -h, --help            Show this help message

Examples:
  sudo ./setup-docker-storage.sh /mnt/storage 500
  sudo ./setup-docker-storage.sh -d /mnt/storage -s 250 -t /var/lib/docker
EOF
    exit "${1:-0}"
}

# Allow viewing help without root
for arg in "$@"; do
    if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
        usage 0
    fi
done

if [[ $EUID -ne 0 ]]; then
   echo "❌ Error: This script must be run as root (use sudo)." >&2
   usage 1
fi

STORAGE_DIR=""
SIZE_GB="500"
TARGET_DIR="/var/lib/docker"
IMG_NAME="docker-storage.img"

# Parse flags and positional arguments
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--dir)
            STORAGE_DIR="$2"
            shift 2
            ;;
        -s|--size)
            SIZE_GB="$2"
            shift 2
            ;;
        -t|--target)
            TARGET_DIR="$2"
            shift 2
            ;;
        -i|--image-name)
            IMG_NAME="$2"
            shift 2
            ;;
        -h|--help)
            usage 0
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

# Fill from positional arguments if not provided via flags
if [[ -z "${STORAGE_DIR}" && ${#POSITIONAL_ARGS[@]} -gt 0 ]]; then
    STORAGE_DIR="${POSITIONAL_ARGS[0]}"
fi
if [[ ${#POSITIONAL_ARGS[@]} -gt 1 ]]; then
    SIZE_GB="${POSITIONAL_ARGS[1]}"
fi
if [[ ${#POSITIONAL_ARGS[@]} -gt 2 ]]; then
    TARGET_DIR="${POSITIONAL_ARGS[2]}"
fi

if [[ -z "${STORAGE_DIR}" ]]; then
    echo "❌ Error: Storage directory not specified." >&2
    usage 1
fi

if [[ ! -d "${STORAGE_DIR}" ]]; then
    echo "❌ Error: Storage directory '${STORAGE_DIR}' does not exist or is not mounted." >&2
    exit 1
fi

IMG_PATH="${STORAGE_DIR%/}/${IMG_NAME}"

echo "=========================================================="
echo "🐳 Configuring Docker Storage Volume"
echo "   Storage Path:    ${IMG_PATH}"
echo "   Max Virtual Cap: ${SIZE_GB} GB (sparse, grows dynamically)"
echo "   Mount Target:    ${TARGET_DIR}"
echo "=========================================================="

# 1. Stop Docker services
echo "1️⃣  Stopping Docker service..."
systemctl stop docker.socket 2>/dev/null || true
systemctl stop docker.service 2>/dev/null || true

# 2. Create sparse loopback disk image if it doesn't already exist
if [[ -f "${IMG_PATH}" ]]; then
    echo "ℹ️  Existing image found at ${IMG_PATH}. Reusing existing image."
else
    echo "2️⃣  Creating ${SIZE_GB}GB sparse disk image at ${IMG_PATH}..."
    truncate -s "${SIZE_GB}G" "${IMG_PATH}"
    
    echo "3️⃣  Formatting ${IMG_PATH} with ext4..."
    mkfs.ext4 -F -L docker_storage "${IMG_PATH}"
fi

# 3. Ensure mount directory exists
mkdir -p "${TARGET_DIR}"

# 4. Mount image
if mountpoint -q "${TARGET_DIR}"; then
    echo "ℹ️  ${TARGET_DIR} is already a mountpoint."
else
    echo "4️⃣  Mounting loop device to ${TARGET_DIR}..."
    mount -o loop "${IMG_PATH}" "${TARGET_DIR}"
fi

# 5. Persist to /etc/fstab
FSTAB_ENTRY="${IMG_PATH} ${TARGET_DIR} ext4 defaults,loop 0 0"
if grep -Fq "${IMG_PATH}" /etc/fstab; then
    echo "ℹ️  /etc/fstab entry already present."
else
    echo "5️⃣  Adding mount entry to /etc/fstab..."
    echo "${FSTAB_ENTRY}" >> /etc/fstab
fi

# 6. Start Docker service
echo "6️⃣  Enabling and starting Docker service..."
systemctl enable docker.socket 2>/dev/null || true
systemctl enable docker.service 2>/dev/null || true
systemctl start docker.service

# Ensure CLI context points to default native docker socket
if command -v docker >/dev/null 2>&1; then
    docker context use default 2>/dev/null || true
fi

# 7. Verification
echo "7️⃣  Verifying Docker storage..."
DOCKER_ROOT=$(docker info --format '{{.DockerRootDir}}' 2>/dev/null || echo "${TARGET_DIR}")
DRIVER=$(docker info --format '{{.Driver}}' 2>/dev/null || echo "unknown")
AVAILABLE_SPACE=$(df -h "${TARGET_DIR}" | awk 'NR==2 {print $4}')

echo "──────────────────────────────────────────────────────────"
echo "✅ Docker storage configured successfully!"
echo "   Root Dir:        ${DOCKER_ROOT}"
echo "   Storage Driver:  ${DRIVER}"
echo "   Available Space: ${AVAILABLE_SPACE}"
echo "──────────────────────────────────────────────────────────"
echo "You can now build the image and run agy-docker."
