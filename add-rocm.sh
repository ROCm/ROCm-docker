#!/bin/bash
# #################################################
# Copyright (c) 2017 Advanced Micro Devices, Inc.
# #################################################
# Author: Paul Fultz II

set -e

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

if uname -r | grep -q 'rocm'; then
    KERNEL_VERSION=$(uname -r | sed 's/.*rocm-rel-//g')
    KERNEL_PATCH_VERSION=$(echo $KERNEL_VERSION | sed 's/.*-//g')
    ROCM_VERSION=$(echo $KERNEL_VERSION | sed 's/-.*//g')

    if [ "$ROCM_VERSION" == "1.4" ]
    then
        download_repo http://repo.radeon.com/rocm/archive/apt_1.4.0.tar.bz2
    elif [ "$ROCM_VERSION" == "1.5" ]
    then
        download_repo http://repo.radeon.com/rocm/archive/apt_1.5.1.tar.bz2
    elif [ "$ROCM_VERSION" == "1.6" ] && [ "$KERNEL_PATCH_VERSION" == "77" ]
    then
        download_repo http://repo.radeon.com/rocm/archive/apt_1.6.0.tar.bz2
    elif [ "$ROCM_VERSION" == "1.6" ] # Latest patch version is 180
    then
        download_repo http://repo.radeon.com/rocm/archive/apt_1.6.4.tar.bz2
    else
        add_repo http://repo.radeon.com/rocm/apt/debian/
    fi

else
    KERNEL_VERSION=$(cat /sys/module/amdkfd/version)
    KERNEL_SRC_VERSION=$(cat /sys/module/amdkfd/srcversion)
    if [ "$KERNEL_VERSION" == "2.0.0" ]; then
        # 1.7.137
        if [ "$KERNEL_SRC_VERSION" == "13FF90CA7D6AC14290ADCFD" ] || [ "$KERNEL_SRC_VERSION" == "3A26446A606958428B1B870" ]; then
            download_repo http://repo.radeon.com/rocm/archive/apt_1.7.2.tar.bz2
        # 1.8.118
        elif [ "$KERNEL_SRC_VERSION" == "B9B5387F6B6FEA02D977638" ]; then
            download_repo http://repo.radeon.com/rocm/archive/apt_1.8.0.tar.bz2
        # 1.8-151 -> 1.8.1
        # 1.8.192
        elif [ "$KERNEL_SRC_VERSION" == "E657186569CAA8D3E3727BA" ]; then
            download_repo http://repo.radeon.com/rocm/archive/apt_1.8.2.tar.bz2
        else
            add_repo http://repo.radeon.com/rocm/apt/debian/
        fi
    else
        add_repo http://repo.radeon.com/rocm/apt/debian/
    fi

fi

# Install key
wget -O - http://repo.radeon.com/rocm/apt/debian/rocm.gpg.key | apt-key add -
apt-get update
