#!/usr/bin/env bash

# Series of steps to build layers of containers, each container housing 1 softare component
( cd rock; docker build -f rock-deb-dockerfile -t roc/rock . )
( cd roct; docker build -f roct-thunk-release-dockerfile -t roc/roct . )
( cd rocr; docker build -f rocr-make-release-dockerfile -t roc/rocr . )
( cd  hcc; docker build -f hcc-release-dockerfile -t roc/hcc . )
( cd hcblas; docker build -f hcblas-release-dockerfile -t roc/hcblas . )

echo ""
echo "The host machine needs to be configured with the proper ROC Kernel modules"
echo "example sequence below:"
echo ""
echo "cd /usr/local/src"
echo "git clone --no-checkout --depth=1 https://github.com/RadeonOpenCompute/ROCK-Kernel-Driver.git"
echo "cd ROCK-Kernel-Driver"
echo "git checkout master -- packages/ubuntu"
echo "DEBIAN_FRONTEND=noninteractive dpkg -i packages/ubuntu/*.deb"
echo "echo \"KERNEL==\"kfd\", MODE=\"0666\"\" | sudo tee /etc/udev/rules.d/kfd.rules"
