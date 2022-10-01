#!/bin/sh

OS=${OS:-ubuntu}
OS_VERSION=${OS_VERSION:-20.04}
OS_VARIANT=${OS_VARIANT:-${OS}-${OS_VERSION}}
ROCM_VERSION=5.2.3
AMDGPU_VERSION=22.20.3
#TERM_FLAVOR=""
TERM_FLAVOR="-complete-sdk"
RENDER_GID=$(getent group render | cut --delimiter ':' --fields 3)

cat >.env <<EOF
OS_VARIANT=${OS_VARIANT}
ROCM_VERSION=${ROCM_VERSION}
AMDGPU_VERSION=${AMDGPU_VERSION}
TERM_FLAVOR=${TERM_FLAVOR}
UID=${UID:-$(id -u)}
RENDER_GID=${RENDER_GID}
EOF

# choose your compose tool
COMPOSE="docker-compose"
#COMPOSE="docker compose"

# build rocm/dev-${OS_VARIANT}:${ROCM_VERSION}
${COMPOSE} build base # && docker tag rocm/dev-${OS_VARIANT}:${ROCM_VERSION} rocm/dev-${OS_VARIANT}:latest
ret=$?
[ $ret -eq 0 ] || exit $ret

# build rocm/dev-${OS_VARIANT}:${ROCM_VERSION}-${FLAVOR}
FLAVORS="vulkan opencl opencl-ml opencl-sdk hip hip-libs hip-ml hip-sdk openmp-sdk complete complete-sdk"
for flavor in ${FLAVORS}; do
  ${COMPOSE} build ${flavor} # && docker tag rocm/dev-${OS_VARIANT}:${ROCM_VERSION}-${FLAVOR} rocm/dev-${OS_VARIANT}:latest-${FLAVOR}
done

# build rocm-terminal:${ROCM_VERSION}-${OS_VARIANT}${TERM_FLAVOR}
${COMPOSE} build term # && docker tag rocm/rocm-terminal:${ROCM_VERSION}-${OS_VARIANT}${TERM_FLAVOR} rocm/rocm-terminal:latest-${OS_VARIANT}${TERM_FLAVOR}
${COMPOSE} build xterm # && docker tag rocm/rocm-terminal:${ROCM_VERSION}-${OS_VARIANT}${TERM_FLAVOR}-x11 rocm/rocm-terminal:latest-${OS_VARIANT}${TERM_FLAVOR}-x11
