#!/usr/bin/env bash
# build.sh: Build the agy-base Docker image

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="${AGY_IMAGE:-agy-base:latest}"

echo "🔨 Building Docker image: ${IMAGE_NAME}..."
docker build \
    --build-arg HOST_UID="$(id -u)" \
    --build-arg HOST_GID="$(id -g)" \
    -t "${IMAGE_NAME}" \
    "${SCRIPT_DIR}"

echo "✅ Build finished successfully: ${IMAGE_NAME}"
