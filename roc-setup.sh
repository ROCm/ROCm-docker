#!/usr/bin/env bash
echo "Compiling release-mode docker images (minimizing size and no debug symbols)"

# Series of steps to build layers of containers, each container housing 1 softare component
( cd rock; docker build -f rock-deb-dockerfile -t roc/rock . )
( cd roct; docker build -f roct-thunk-release-dockerfile -t roc/roct . )
( cd rocr; docker build -f rocr-make-release-dockerfile -t roc/rocr . )
( cd hcc-hsail; docker build -f hcc-release-dockerfile -t roc/hcc-hsail . )
( cd hcc-isa; docker build -f hcc-isa-release-dockerfile -t roc/hcc-isa . )

echo "Use the /hcc-project build context to build a custom application container"
echo "Copy /hcc-project into a new folder and modify to taste"
echo ""
echo "In order to run ROC docker containers, the host machine needs to"
echo "be configured with ROC Kernel modules, similar to the actions taken"
echo "in the ROCK 'rock-deb-dockerfile' dockerfile"
echo "In summary, the following sequence prepares the host:"
echo ""
echo "cd /usr/local/src"
echo "git clone --no-checkout --depth=1 https://github.com/RadeonOpenCompute/ROCK-Kernel-Driver.git"
echo "cd ROCK-Kernel-Driver"
echo "git checkout master -- packages/ubuntu"
echo "dpkg -i packages/ubuntu/*.deb"
echo "echo \"KERNEL==\"kfd\", MODE=\"0666\"\" | sudo tee /etc/udev/rules.d/kfd.rules"
