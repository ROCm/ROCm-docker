# Preparing a machine to run with ROCm and docker

The following instructions assume a fresh/blank machine to be prepared for the ROCm + Docker environment; no additional software has been installed other than the typical stock package updating.

It is recommended to install the ROCm kernel first. The ROCm KFD is distributed as DKMS modules for post ROCm1.7.0 releases. However, we recommend to upgrade to newer generic kernels as possible. The newer kernel often supports AMD hardware better, and stock video resolutions and hardware acceleration performance are typically improved. As of the time of this writing, ROCm officially supports Ubuntu and Fedora Linux distributions.  The following asciicast demonstrates updating the kernel on Ubuntu 16.04.  More detailed instructions can be found on the Radeon Open Compute website:
* [Installing ROCK kernel](https://github.com/RadeonOpenCompute/ROCm#debian-repository---apt-get) on Ubuntu

### Step 1: Install rocm-kernel
The following is a sequence of commands to type (or cut-n-paste) into a terminal:

```bash
# OPTIONAL, upgrade your base kernel to 4.13.0-32-generic, reboot required
sudo apt update && sudo apt install linux-headers-4.13.0-32-generic linux-image-4.13.0-32-generic linux-image-extra-4.13.0-32-generic linux-signed-image-4.13.0-32-generic
sudo reboot 

# Install the ROCm rock-dkms kernel modules, reboot required
wget -qO - http://repo.radeon.com/rocm/apt/debian/rocm.gpg.key | sudo apt-key add -
echo deb [arch=amd64] http://repo.radeon.com/rocm/apt/debian/ xenial main | sudo tee /etc/apt/sources.list.d/rocm.list
sudo apt-get update && sudo apt-get install rock-dkms
sudo update-initramfs -u
sudo reboot

# Add user to the video group
sudo adduser $LOGNAME video
```
Make sure to reboot the machine after installing the ROCm kernel package to force the new kernel to load on reboot.  You can verify the ROCm kernel is loaded by typing the following command at a prompt:

```bash
lsmod | grep kfd
```

Printed on the screen should be similar as follows:
```bash
amdkfd                270336  4
amd_iommu_v2           20480  1 amdkfd
amdkcl                 24576  3 amdttm,amdgpu,amdkfd
```

### Step 2: Install docker
After verifying the new kernel is running, next install the docker engine.  Manual instructions to install docker on various distro's can be found on the [docker website](https://docs.docker.com/engine/installation/linux/), but perhaps the simplest method is to use a bash script available from docker itself.  If it's OK in your organization to run a bash script on your machine downloaded from the internet, open a bash prompt and execute the following line:

```bash
curl -sSL https://get.docker.com/ | sh
```

The above script looks at the linux distribution and the installed kernel, and installs docker appropriately.  The script will output a warning message on a ROCm platform saying that it does not recognize the rocm kernel; this is normal and can be safely ignored.  The script does proper docker installation without recognizing the kernel.

### Step 3: Verify/Change the docker device storage driver
The docker device storage driver manages how docker accesses images and containers.  There are many available, and [documentation and thorough descriptions](https://docs.docker.com/engine/userguide/storagedriver/imagesandcontainers/) on storage driver architecture can be found on the official docker website.  It is possible to check which storage driver docker is using by issuing a

```bash
sudo docker info
```

command at the command prompt and looking for the *'Storage Driver: '* output.  It is hard to predict what storage driver Docker will choose as default on install, and defaults change over time, but in our experience we have run into a problems with the *'devicemapper'* storage driver with large image sizes.  The *'devicemapper'* storage driver imposes limitations on the maximum size images and containers can be.  If you work in a field of 'big data', such as in DNN applications, the 10 GB default limit of *'devicemapper'* is limiting.  There are two options available if you run into this limit:

1.  Switch to a different storage driver
    * **AMD recommends using 'overlay2'**, whose dependencies are met by the ROCm kernel and should be available
      * [overlay2](https://docs.docker.com/engine/userguide/storagedriver/overlayfs-driver/) provides for unlimited image size
    * If 'overlay2' is not an option, storage drivers can be [chosen at service startup time](https://docs.docker.com/engine/userguide/storagedriver/selectadriver/) with the **--storage-driver=&lt;name&gt;** option
2.  If you must stick with 'devicemapper', pass the 'devicemapper' [configuration variable](https://docs.docker.com/engine/reference/commandline/dockerd/) --dm.basesize on service startup to increase the potential image maximum

The downside to switching to the 'overlay2' storage driver after creating and working with 'devicemapper' images is that existing images need to be recreated.  As such, we recommend verifying that docker be set up using the 'overlay2' storage driver before engaging in significant work.

### Step 4a: Build ROCm container using docker CLI
[![asciicast](https://asciinema.org/a/5u0d81txy9tskiitcispluw9v.png)](https://asciinema.org/a/5u0d81txy9tskiitcispluw9v)

* Clone and build the container

```bash
git clone https://github.com/RadeonOpenCompute/ROCm-docker
cd ROCm-docker
sudo docker build -t rocm/rocm-terminal rocm-terminal
sudo docker run -it --device=/dev/kfd --device=/dev/dri --group-add video rocm/rocm-terminal
```

### (optional) Step 4b: Build ROCm container using docker-compose
[![asciicast](https://asciinema.org/a/77cfxjz9ilt2x9ck27r9vanu7.png)](https://asciinema.org/a/77cfxjz9ilt2x9ck27r9vanu7)

* Clone and build the container using [docker-compose](https://docs.docker.com/compose/install/)

```bash
git clone https://github.com/RadeonOpenCompute/ROCm-docker
cd ROCm-docker
sudo docker-compose run --rm rocm
```
### Step 5: Verify successful build of ROCm-docker container
*  Verify a working container-based ROCm software stack
  * After step #2 or #3, a bash login prompt to a running docker container should be available
      * `hcc --version` should display version information of the AMD heterogeneous compiler
  * Execute sample application
      * `cd /opt/rocm/hsa/sample`
      * `sudo make`
      * `./vector-copy`
  * Text displaying successful creation of a GPU device, successful kernel compilation and successful shutdown should be printed to stdout
