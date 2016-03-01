#!/usr/bin/env bash
echo "Compiling release-mode docker images (minimizing size and no debug symbols)"

# Series of steps to build layers of containers, each container housing 1 softare component
( cd rock; docker build -f rock-deb-dockerfile -t roc/rock . )
( cd roct; docker build -f roct-thunk-release-dockerfile -t roc/roct . )
( cd rocr; docker build -f rocr-make-release-dockerfile -t roc/rocr . )
( cd hcc-hsail; docker build -f hcc-release-dockerfile -t roc/hcc-hsail . )
( cd hcc-isa; docker build -f hcc-isa-release-dockerfile -t roc/hcc-isa . )
( cd hcblas; docker build -f hcblas-release-dockerfile -t roc/hcblas . )

echo ""
echo "In order to run these docker containers, the host machine will need to"
echo "be configured with the ROC Kernel modules in order to prepare the host"
echo "with the proper kernel and modules"
echo "The following sequence prepares the host, and needs to be run manually:"
echo ""
echo "cd /usr/local/src"
echo "git clone --no-checkout --depth=1 https://github.com/RadeonOpenCompute/ROCK-Kernel-Driver.git"
echo "cd ROCK-Kernel-Driver"
echo "git checkout master -- packages/ubuntu"
echo "dpkg -i packages/ubuntu/*.deb"
echo "echo \"KERNEL==\"kfd\", MODE=\"0666\"\" | sudo tee /etc/udev/rules.d/kfd.rules"
