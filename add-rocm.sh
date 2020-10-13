
#!/bin/bash
# #################################################
# Copyright (c) 2017 Advanced Micro Devices, Inc.
# #################################################
# Author: Paul Fultz II

set -ex

apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y curl bzip2 apt-utils wget

function add_repo {
    sh -c "echo deb [arch=amd64] $1 xenial main > /etc/apt/sources.list.d/rocm.list"
}

function add_local_repo {
    sh -c "echo deb [trusted=yes] file://$1 xenial main > /etc/apt/sources.list.d/rocm.list"
}

function download_repo {
    mkdir -p /repo/tmp
    curl $1 | tar --strip-components=1 -x --bzip2 -C /repo/tmp
    # Some archives are in a debian directory
    if [ -d "/repo/tmp/debian" ]; then
        mv /repo/tmp /repo/radeon
    else
        mkdir -p /repo/radeon
        mv /repo/tmp /repo/radeon/debian
    fi
    cat /repo/radeon/debian/rocm.gpg.key | apt-key add -
    add_local_repo /repo/radeon/debian
}


if [ -e /sys/module/amdgpu/version ]; then
    KERNEL_VERSION=$(cat /sys/module/amdgpu/version)
    KERNEL_SRC_VERSION=$(cat /sys/module/amdgpu/srcversion)
    
    if [ "$KERNEL_VERSION" == "18.30.2.15" ]; then
        download_repo http://repo.radeon.com/rocm/archive/apt_1.9.2.tar.bz2
    elif [ "$KERNEL_VERSION" == "19.10.0.418" ]; then
        download_repo http://repo.radeon.com/rocm/archive/apt_2.0.0.tar.bz2
    elif [ "$KERNEL_VERSION" == "19.10.7.418" ]; then
        add_repo http://repo.radeon.com/rocm/apt/2.1
    elif [ "$KERNEL_VERSION" == "19.10.8.418" ]; then
        add_repo http://repo.radeon.com/rocm/apt/2.2
    elif [ "$KERNEL_VERSION" == "5.0.19.20.6" ]; then
        add_repo http://repo.radeon.com/rocm/apt/2.3
    elif [ "$KERNEL_VERSION" == "5.0.19.20.14" ]; then
        add_repo http://repo.radeon.com/rocm/apt/2.4
    elif [ "$KERNEL_VERSION" == "19.10.9.418" ]; then
        add_repo http://repo.radeon.com/rocm/apt/2.5
    elif [ "$KERNEL_VERSION" == "5.0.71" ]; then
        add_repo http://repo.radeon.com/rocm/apt/2.6
    elif [ "$KERNEL_VERSION" == "5.0.76" ]; then
        add_repo http://repo.radeon.com/rocm/apt/2.7
    elif [ "$KERNEL_VERSION" == "5.0.79" ]; then
        add_repo http://repo.radeon.com/rocm/apt/2.8.0
    elif [ "$KERNEL_VERSION" == "5.0.82" ]; then
        add_repo http://repo.radeon.com/rocm/apt/2.10.0
    elif [ "$KERNEL_VERSION" == "5.2.4" ]; then
        add_repo http://repo.radeon.com/rocm/apt/3.0
    elif [ "$KERNEL_VERSION" == "5.4.4" ]; then
        add_repo http://repo.radeon.com/rocm/apt/3.1
    else
        add_repo http://repo.radeon.com/rocm/apt/debian/
    fi

else
    add_repo http://repo.radeon.com/rocm/apt/debian/
fi

# Install key
wget -O - http://repo.radeon.com/rocm/rocm.gpg.key | apt-key add -
apt-get update

