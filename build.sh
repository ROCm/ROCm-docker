#!/bin/sh

OS_VARIANT=${OS_VARIANT:-ubuntu-20.04}
ROCM_VERSION=5.2.3
AMDGPU_VERSION=22.20.3
TERM_IMAGE_VARIANT=""
#TERM_IMAGE_VARIANT="-complete"
RENDER_GID=$(getent group render | cut --delimiter ':' --fields 3)

cat >.env <<EOF
OS_VARIANT=${OS_VARIANT}
ROCM_VERSION=${ROCM_VERSION}
AMDGPU_VERSION=${AMDGPU_VERSION}
TERM_IMAGE_VARIANT=${TERM_IMAGE_VARIANT}
RENDER_GID=${RENDER_GID}
EOF

# choose your compose tool
COMPOSE="docker-compose"
#COMPOSE="docker compose"

# build rocm/dev-${OS_VARIANT}:${ROCM_VERSION}
${COMPOSE} build dev
ret=$?
[ $ret -eq 0 ] && docker tag rocm/dev-${OS_VARIANT}:${ROCM_VERSION} rocm/dev-${OS_VARIANT}:latest

if [ $ret -eq 0 -a "$OS_VARIANT" != "centos-7" ]; then

# build rocm/dev-${OS_VARIANT}:${ROCM_VERSION}-complete
${COMPOSE} build dev-complete

# build rocm-terminal:${ROCM_VERSION}-${OS_VARIANT}${TERM_IMAGE_VARIANT}
${COMPOSE} build rocm

fi
