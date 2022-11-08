# Preparing a machine to run with ROCm and docker

The following instructions assume a fresh/blank machine to be prepared for the ROCm + Docker environment; no additional software has been installed other than the typical stock package updating.

Please refer to the following instructions for full documentation to install the ROCm base support:
* [ROCm Installation Guide](https://docs.amd.com/bundle/ROCm-Installation-Guide-v5.3/page/Introduction_to_ROCm_Installation_Guide_for_Linux.html)

### Step 1: Install amdgpu
The following is a sequence of commands to type (or cut-n-paste) into a terminal, make sure your kernel driver is supported [here](https://github.com/RadeonOpenCompute/ROCm#supported-operating-systems):

```bash
# Install the ROCm rock-dkms kernel modules, reboot required
sudo apt-get update
wget https://repo.radeon.com/amdgpu-install/5.3/ubuntu/focal/amdgpu-install_5.3.50300-1_all.deb 
sudo apt-get install ./amdgpu-install_5.3.50300-1_all.deb
sudo amdgpu-install --usecase=rocm

# Add user to the render group if you're using Ubuntu20.04
sudo usermod -a -G render $LOGNAME

# To add future users to the video and render groups, run the following command:
echo 'ADD_EXTRA_GROUPS=1' | sudo tee -a /etc/adduser.conf
echo 'EXTRA_GROUPS=video' | sudo tee -a /etc/adduser.conf
echo 'EXTRA_GROUPS=render' | sudo tee -a /etc/adduser.conf 

```
Make sure to reboot the machine after installing the ROCm kernel package to force the new kernel to load on reboot.  You can verify the ROCm kernel is loaded by typing the following command at a prompt:

```bash
lsmod | grep amdgpu
```

Printed on the screen should be similar as follows:
```bash
amdgpu               3530752  0
amdttm                 94208  1 amdgpu
amd_sched              28672  1 amdgpu
amdkcl                 24576  3 amdttm,amdgpu,amd_sched
i2c_algo_bit           16384  2 amdgpu,ast
amd_iommu_v2           20480  1 amdgpu
drm_kms_helper        167936  2 amdgpu,ast
drm                   360448  8 amdttm,amdgpu,ast,amdkcl,amd_sched,ttm,drm_kms_helper
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
sudo docker run -it --device=/dev/kfd --device=/dev/dri --security-opt seccomp=unconfined --group-add video rocm/rocm-terminal
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
  * Execute rocminfo script
      * `/opt/rocm/bin/rocminfo`
  * Text displaying your system AMD GPU System Attributes and enumerate all the visible GPU Agents. 
