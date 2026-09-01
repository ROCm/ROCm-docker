#!/bin/bash
# install_rocm_deps.sh
#
# Installs runtime dependencies for ROCm on various Linux distributions.
# Automatically detects the distribution and uses the appropriate package manager.
#
# Supported distributions:
#   - Ubuntu 22.04, 24.04, 26.04 (apt)
#   - Debian (apt)
#   - AlmaLinux 8 (dnf)
#   - Azure Linux 3 (tdnf)

set -e

# Detect distribution type from /etc/os-release
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

DISTRO=$(detect_distro)
echo "Detected distribution: $DISTRO"

case "$DISTRO" in
    ubuntu|debian)
        echo "Installing dependencies using apt..."
        apt-get update
        apt-get install -y --no-install-recommends \
            apt-utils \
            autoconf \
            automake \
            ca-certificates \
            build-essential \
            cmake \
            cmake-curses-gui \
            curl \
            dialog \
            doxygen \
            flex \
            git \
            kmod \
            libelf1 \
            libelf-dev \
            libfftw3-dev \
            libjpeg-dev \
            libtool \
            libnuma1 \
            libnuma-dev \
            libunwind8 \
            libncurses5-dev \
            libncurses6 \
            less \
            ninja-build \
            opencl-dev \
            perl \
            file \
            nano \
            openssh-client \
            rsync \
            sudo \
            swig \
            vim-nox \
            wget \
            python3 \
            python3-dev \
            python3-pip \
            python3-venv \
            python3-setuptools \
            python3-wheel \
            pkg-config \
            liblzma-dev \
            libdrm-dev \
            zlib1g-dev
        if [ "$DISTRO" = "ubuntu" ]; then
            apt-get install -y --no-install-recommends software-properties-common
        fi
        # libdw: libdw1t64 for Ubuntu 24.04+, libdw1 for older versions
        apt-get install -y --no-install-recommends libdw1t64 2>/dev/null || \
            apt-get install -y --no-install-recommends libdw1 || true
        # libssl: libssl3 for Ubuntu 22.04+, libssl1.1 for older versions
        apt-get install -y --no-install-recommends libssl3 2>/dev/null || \
            apt-get install -y --no-install-recommends libssl1.1 || true
        rm -rf /var/lib/apt/lists/*
        ;;

    almalinux)
        echo "Installing dependencies using dnf..."
        # Fix AlmaLinux repo to use direct baseurl instead of mirrorlist
        if [ -f /etc/yum.repos.d/almalinux.repo ]; then
            sed -i 's/^mirrorlist=/#mirrorlist=/g' /etc/yum.repos.d/almalinux.repo
            sed -i 's/^# baseurl=/baseurl=/g' /etc/yum.repos.d/almalinux.repo
        fi
        dnf install -y --setopt=install_weak_deps=False \
            autoconf \
            automake \
            ca-certificates \
            cmake \
            curl \
            doxygen \
            flex \
            gcc \
            gcc-c++ \
            git \
            libatomic \
            elfutils-libelf \
            elfutils-libelf-devel \
            elfutils-libs \
            file \
            less \
            libjpeg-turbo-devel \
            libtool \
            make \
            ninja-build \
            numactl-libs \
            numactl-devel \
            ncurses-libs \
            openssl-libs \
            openssh-clients \
            perl \
            sudo \
            swig \
            vim-enhanced \
            wget \
            python3 \
            python3-devel \
            python3-pip \
            python3-setuptools \
            python3-wheel \
            kmod \
            zlib-devel
        dnf clean all
        ;;

    azurelinux)
        echo "Installing dependencies using tdnf..."
        tdnf install -y \
            autoconf \
            automake \
            ca-certificates \
            cmake \
            curl \
            gcc \
            gcc-c++ \
            git \
            make \
            ninja-build \
            tar \
            libatomic \
            elfutils-libelf \
            elfutils-libs \
            file \
            less \
            libjpeg-turbo-devel \
            numactl-libs \
            numactl-devel \
            libunwind \
            ncurses-libs \
            openssl-libs \
            openssh-clients \
            perl \
            sudo \
            vim \
            wget \
            python3 \
            python3-devel \
            python3-pip \
            kmod \
            zlib-devel
        tdnf clean all
        ;;

    *)
        echo "Error: Unsupported distribution: $DISTRO"
        echo "Supported distributions: ubuntu, debian, almalinux, azurelinux"
        exit 1
        ;;
esac

echo "Dependencies installed successfully for $DISTRO"
