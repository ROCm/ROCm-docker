#!/bin/sh

OS=${OS:-ubuntu}
OS_VERSION=${OS_VERSION:-24.04}
OS_VARIANT=${OS_VARIANT:-${OS}-${OS_VERSION}}
ROCM_VERSION=${ROCM_VERSION:-6.2}
AMDGPU_VERSION=${AMDGPU_VERSION:-6.2}
#TERM_FLAVOR=""
TERM_FLAVOR="-complete-sdk"
XTERM_FLAVOR="-complete"
RENDER_GID=$(getent group render | cut --delimiter ':' --fields 3)

cat >.env <<EOF
OS_VARIANT=${OS_VARIANT}
ROCM_VERSION=${ROCM_VERSION}
AMDGPU_VERSION=${AMDGPU_VERSION}
TERM_FLAVOR=${TERM_FLAVOR}
XTERM_FLAVOR=${XTERM_FLAVOR}
UID=${UID:-$(id -u)}
RENDER_GID=${RENDER_GID}
EOF

# choose your compose tool
COMPOSE="docker-compose"
#COMPOSE="docker compose"

# build rocm/dev-${OS_VARIANT}:${ROCM_VERSION}
${COMPOSE} build base || exit $?
# docker tag rocm/dev-${OS_VARIANT}:${ROCM_VERSION} rocm/dev-${OS_VARIANT}:latest

# build rocm/dev-${OS_VARIANT}:${ROCM_VERSION}-${FLAVOR}
FLAVORS="openmp-sdk opencl opencl-sdk hip hip-sdk ml ml-sdk complete complete-sdk"
for flavor in ${FLAVORS}; do
  ${COMPOSE} build ${flavor} || exit $?
  # docker tag rocm/dev-${OS_VARIANT}:${ROCM_VERSION}-${FLAVOR} rocm/dev-${OS_VARIANT}:latest-${FLAVOR}
done

# build rocm/rocm-terminal:${ROCM_VERSION}-${OS_VARIANT}${TERM_FLAVOR}
${COMPOSE} build term || exit $?
# docker tag rocm/rocm-terminal:${ROCM_VERSION}-${OS_VARIANT}${TERM_FLAVOR} rocm/rocm-terminal:latest-${OS_VARIANT}${TERM_FLAVOR}

${COMPOSE} build xterm || exit $?
# docker tag rocm/rocm-terminal:${ROCM_VERSION}-${OS_VARIANT}${TERM_FLAVOR}-x11 rocm/rocm-terminal:latest-${OS_VARIANT}${TERM_FLAVOR}-x11
