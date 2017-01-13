### Install rocm-kernel
[![Install rocm-kernel](https://asciinema.org/a/cv0r34re9hp9g5hoja8vyh803.png)](https://asciinema.org/a/cv0r34re9hp9g5hoja8vyh803)

* [Installing ROCK kernel](https://github.com/RadeonOpenCompute/ROCm#debian-repository---apt-get) on Ubuntu 14.04  
  * This step will eventually go away as newer linux kernel images trickle down into upcoming distros.  Our kernel module developers (AMDGPU and AMDKFD) are contributing source back into the mainline linux kernel.  This step of installing a ROCm specific kernel image is temporary.  

```bash
wget -qO - http://packages.amd.com/rocm/apt/debian/rocm.gpg.key | sudo apt-key add -
sudo sh -c 'echo deb [arch=amd64] http://packages.amd.com/rocm/apt/debian/ trusty main  \
    > /etc/apt/sources.list.d/rocm.list'
sudo apt-get update && sudo apt-get install rocm-kernel
```

### Build ROCm container using docker CLI
[![asciicast](https://asciinema.org/a/5u0d81txy9tskiitcispluw9v.png)](https://asciinema.org/a/5u0d81txy9tskiitcispluw9v)

* Clone and build the container

```bash
git clone https://github.com/RadeonOpenCompute/ROCm-docker
cd ROCm-docker
sudo docker build -t rocm/rocm-terminal rocm-terminal
sudo docker run -it --rm --device="/dev/kfd" rocm/rocm-terminal
```

### Build ROCm container using docker-compose
[![asciicast](https://asciinema.org/a/77cfxjz9ilt2x9ck27r9vanu7.png)](https://asciinema.org/a/77cfxjz9ilt2x9ck27r9vanu7)

* Clone and build the container using [docker-compose](https://docs.docker.com/compose/install/)

```bash
git clone https://github.com/RadeonOpenCompute/ROCm-docker
cd ROCm-docker
sudo docker-compose run --rm rocm
```
### Verify successful build of ROCm-docker container
*  Verify a working container-based ROCm software stack
  * After step #2 or #3, a bash login prompt to a running docker container should be available
      * `hcc --version` should display version information of the AMD heterogeneous compiler
  * Execute sample application
      * `cd /opt/rocm/hsa/sample`
      * `sudo make`
      * `./vector-copy`
  * Text displaying successful creation of a GPU device, successful kernel compilation and successful shutdown should be printed to stdout
