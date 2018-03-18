# ROCm-docker

## Radeon Open Compute Platform for docker
This repository contains a framework for building the software layers defined in the Radeon Open Compute Platform into portable docker images.  The following are docker dependencies, which should be installed on the target machine.

-  Docker on [Ubuntu systems](https://docs.docker.com/v1.8/installation/ubuntulinux/) or [Fedora systems](https://docs.docker.com/v1.8/installation/fedora/)
-  Highly recommended: [Docker-Compose](https://docs.docker.com/compose/install/) to simplify container management

# Docker Hub
Looking for an easy start with ROCm + Docker?  The rocm/rocm-terminal image is hosted on [Docker Hub](https://hub.docker.com/r/rocm/rocm-terminal/).  After the [ROCm kernel is installed](#install-rocm-kernel), pull the image from Docker Hub and create a new instance of a container.

```bash
sudo docker pull rocm/rocm-terminal
sudo docker run -it --device=/dev/kfd --device=/dev/dri --group-add video rocm/rocm-terminal
```

## ROCm-docker set up guide
[Installation instructions](quick-start.md) and asciicasts demos are available to help users quickly get running with rocm-docker.  Visit the set up guide to read more.

### F.A.Q
When working with the ROCm containers, the following are common and useful docker commands:
*  A new docker container typically **does not** house apt repository meta-data.  Before trying to install new software using apt, make sure to run `sudo apt update` first
*  A message like the following typically means your user does not have permissions to execute docker; use sudo or [add your user](https://docs.docker.com/engine/installation/linux/ubuntulinux/#/create-a-docker-group) to the docker group.
  * `Cannot connect to the Docker daemon. Is the docker daemon running on this host?`
*  Open another terminal into a running container
  * `sudo docker exec -it <CONTAINER-NAME> bash -l`
* Copy files from host machine into running docker container
  * `sudo docker cp HOST_PATH <CONTAINER-NAME>:/PATH`
* Copy files from running docker container onto host machine
  * `sudo docker cp <CONTAINER-NAME>:/PATH/TO/FILE HOST_PATH`
* If receiving messages about *no space left on device* when pulling images, check the storage driver in use by the docker engine.  If its 'device mapper', that means the image size limits imposed by the 'device mapper' storage driver are a problem
  * Follow the documentation in the [quick start guide](quick-start.md) for a solution to change to the storage driver

#### Saving work in a container
Docker containers are typically ephemeral, and are discarded after closing the container with the '**--rm**' flag to `docker run`.  However, there are times when it is desirable to close a container that has arbitrary work in it, and serialize it back into a docker image.  This may be to to create a checkpoint in a long and complicated series of instructions, or it may be desired to share the image with others through a docker registry, such as docker hub.

```bash
sudo docker ps -a  # Find container of interest
sudo docker commit <container-name> <new-image-name>
sudo docker images # Confirm existence of a new image
```
[![asciicast](https://asciinema.org/a/bka9uj16zuio4qlnsqcr7nv8z.png)](https://asciinema.org/a/bka9uj16zuio4qlnsqcr7nv8z)

# Details
Docker does not virtualize or package the linux kernel inside of an image or container.  This is a design decision of docker to provide lightweight and fast containerization.  The implication for this on the ROCm compute stack is that in order for the docker framework to function, **the ROCm kernel and corresponding modules must be installed on the host machine.**  Containers share the host kernel, so the ROCm KFD component ROCK-Kernel-Driver<sup>[1](#ROCK)</sup> functions outside of docker.

### Installing ROCK on the host machine.
An [apt-get repository](https://github.com/RadeonOpenCompute/ROCm/wiki#installing-from-amd-rocm-repositories) is available to automate the installation of the required kernel and kernel modules.

## Building images
There are two ways to install rocm components:
1.  install from the rocm apt/rpm repository (repo.radeon.com)
2.  build the components from source and run install scripts

The first method produces docker images with the smallest footprint and best building speed.  The footprint is smaller because no developer tools need to be installed in the image, an the images build speed is fastest because typically downloading binaries is much faster than downloading source and then invoking a build process.  Of course, building components allows much greater flexibility on install location and the ability to step through the source with debug builds.  ROCm-docker supports making images either way, and depends on the flags passed to the setup script.

The setup script included in this repository is provides some flexibility to how docker containers are constructed.  Unfortunately, Dockerfiles do not have a preprocessor or template language, so typically build instructions are hardcoded.  However, the setup script allows us to write a primitive 'template', and after running it instantiates baked dockerfiles with environment variables substituted in.  For instance, if you wish to build release images and debug images, first run the setup script to generate release dockerfiles and build the images.  Then, run the setup script again and specify debug dockerfiles and build new images.  The docker images should generate unique image names and not conflict with each other.

## setup.sh
Currently, the setup.sh scripts checks to make sure that it is running on an **Ubuntu system**, as it makes a few assumptions about the availability of tools and file locations.  If running rocm on a Fedora machine, inspect the source of setup.sh and issue the appropriate commands manually.  There are a few parameters to setup.sh of a generic nature that affects all images built after running.  If no parameters are given, built images will be based off of Ubuntu 16.04 with rocm components installed from debians downloaded from repo.radeon.com.  Supported parameters can be queried with `./setup --help`.

| setup.sh parameters | parameter [default]| description |
|-----|-----|-----|
| --ubuntu | xx.yy [16.04] | Ubuntu version for to inherit base image |
| --install-docker-compose | | helper to install the docker-compose tool |

The following parameters are specific to building containers that compile rocm components from source.

| setup.sh parameters | parameter [default]| description |
|-----|-----|-----|
| --tag | string ['master'] | string representing a git branch name |
| --branch | string ['master'] | alias for tag |
| --debug | | build code with debug flags |

`./setup` generates finalized Dockerfiles from textual template files ending with the *.template* suffix.  Each sub-directory of this repository corresponds to a docker 'build context' responsible for a software layer in the ROCm stack.  After running the script, each directory contains generated dockerfiles for building images from debians and from source.

### Docker compose
`./setup` prepares an environment to be controlled with [Docker Compose](https://docs.docker.com/compose/).  While docker-compose is not necessary for proper operation, it is highly recommended.  setup.sh does provide a flag to simplify the installation of this tool. Docker-compose coordinates the relationships between the various ROCm software layers, and it remembers flags that should be passed to docker to expose devices and import volumes.

#### Example of using docker-compose
docker-compose.yml provides services that build and run containers.  YAML is structured data, so it's easy to modify and extend.  The *setup.sh* script generates a *.env* file that docker-compose reads to satisfy the definitions of the variables in the .yml file.
  * `docker-compose run --rm rocm` -- Run container using rocm packages
  * `docker-compose run --rm rocm-from-src` -- Run container with rocm built from source


  | Docker-compose  | description |
  |-----|-----|
  | docker-compose | docker compose executable|
  | run | sub-command to bring up interactive container |
  | --rm | when shutting the container down, delete it |
  | rocm | application service defined in **docker-compose.yml** |

### rocm-user has root privileges by default
The dockerfile that serves as a 'terminal' creates a non-root user called **rocm-user**.  This container is meant to serve as a development environment (therefore `apt-get` is likely needed), the user has been added to the linux sudo group.  Since it is somewhat difficult to set and change passwords in a container (often requiring a rebuild), the password prompt has been disabled for the sudo group.  While this is convenient for development to be able `sudo apt-get install` packages, it does imply *lower security* in the container.

To increase container security:

1.  Eliminate the sudo-nopasswd COPY statement in the dockerfile and replace with
2.  Your own password with `RUN echo 'account:password' | chpasswd`

The docker.ce release 18.02 has known defects working with **rocm-user** account insider docker image.
Please upgrade docker package to the [18.04 build](https://download.docker.com/linux/ubuntu/dists/xenial/pool/nightly/amd64/docker-ce_18.04.0~ce~dev~git20180313.171447.0.6e4307b-0~ubuntu_amd64.deb). 
### Footnotes:
<a name="ROCK">[1]</a> It can be installed into a container, it just doesn't do anything because containers do not go through the traditional boot process.  We actually do provide a container for ROCK-Kernel-Driver, but it not used by the rest of the docker images.  It does provide isolation and a reproducible environment for kernel development.
