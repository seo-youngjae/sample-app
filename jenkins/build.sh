#!/bin/bash
set -eux

IMAGE_NAME="custom-jenkins"
VERSION="1.1"
CPU_PLATFORM=${1:-amd64}

docker build --platform linux/${CPU_PLATFORM} \
  -t ${IMAGE_NAME}-${CPU_PLATFORM}:${VERSION} \
  -f Dockerfile .
