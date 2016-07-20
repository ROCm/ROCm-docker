# ROCm-docker
## Radeon Open Compute Platform for docker
This repository contains a framework for building the software layers defined in the Radeon Open Compute Platform into portable docker images.  The following are docker dependencies, which should be installed on the target machine.

-  Docker on [Ubuntu systems](https://docs.docker.com/v1.8/installation/ubuntulinux/) or [Fedora systems](https://docs.docker.com/v1.8/installation/fedora/)
-  Highly recommended: [Docker-Compose](https://docs.docker.com/compose/install/) to simplify container management

## ROCm-docker quick start videos
### Install rocm-kernel
[![Install rocm-kernel](https://asciinema.org/a/cv0r34re9hp9g5hoja8vyh803.png)](https://asciinema.org/a/cv0r34re9hp9g5hoja8vyh803)

* [Installing ROCK kernel](https://github.com/RadeonOpenCompute/ROCm#debian-repository---apt-get) on Ubuntu 14.04  

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

### Commit container state to docker image
[![asciicast](https://asciinema.org/a/bka9uj16zuio4qlnsqcr7nv8z.png)](https://asciinema.org/a/bka9uj16zuio4qlnsqcr7nv8z)

* Demonstrates saving a container with arbitrary work into a new docker image.  The new image serves as a checkpoint, that can be distributed to other users or used as a good known state

```bash
sudo docker ps -a
sudo docker commit <container-name> <new-image-name>
sudo docker images
```

# Details
Docker does not virtualize or package the linux kernel inside of an image or container.  This is a design decision of docker to provide the lightweight and fast containerization.  The implication for this on the ROCm compute stack is that in order for the docker framework to function, **the ROCm kernel and corresponding modules must be installed on the host machine.**  All containers share the host kernel, The ROCm component that can not be used in a docker image is the ROCK-Kernel-Driver<sup>[1](#ROCK)</sup>.

### Installing ROCK on the host machine.
An [apt-get repository](https://github.com/RadeonOpenCompute/ROCm/wiki#installing-from-amd-rocm-repositories) is available to automate the installation of the required kernel and kernel modules.

## How to build ROCm containers from source
While it is nice to quickly bring up a ROCm container from the latest apt-get release version, sometimes it is nice to be able to play with the latest development code.  At the root of this repository is a bash script `./rocm-setup`.  It creates a set of Dockerfiles building the ROCm software components from source, with a yaml file used by `docker-compose` to manage the relationships between these containers.
```bash
Usage: ./rocm-setup [--master | --develop] [--release | --debug]
Default flags: --master --release

--master) Build dockerfiles from stable master branches; exclusive with --develop
--develop) Build dockerfiles from integration branches; exclusive with --master
--release) Build release containers; minimizes size of docker images; exclusive with --debug
--debug) Build debug containers; symbols generated and build tree intact for debugging; exclusive with --release
```

`./rocm-setup` generates Dockerfiles from textual template files ending with the .template suffix.  Each sub-directory of this repository corresponds to a docker 'build context' responsible for a software layer in the ROCm stack.  After running the script, each directory contains a generated 'Dockerfile'.  The parameters to the script control the flavor of the components to build, for instance: debug builds of the /develop branches.

### ROCm component dictionary

| ROC component | |
|-----|-----|
| roct | the kernel thunk library |
| rocr | the runtime |
| hcc-hsail | the compiler that generates HSAIL IL from the backend |
| hcc-lc | the compiler that generates GPU ISA from the backend |

### What git branches are built with ./rocm-setup

|| --master | --develop |
|------|-----|-----|
|roct| master | dev |
|rocr| master | dev |
|hcc-hsail| master | develop |
|hcc-lc| testing | master |

### Docker compose
`./rocm-setup` prepares an environment that can be controlled with [Docker Compose](https://docs.docker.com/compose/).  An output of the script is a **docker-compose.yml** file in the root of the repository, which coordinates the relationships between the various ROCm software layers.  Additionally, the  docker-compose.yml file can be extended to easily launch interactive application or development containers built on top of the ROCm software stack.  

#### Running a ROCm container using binaries built from source
Using docker-compose, a target is provided that will import the data-only containers which build the individual ROCm components.  If the images are not yet built, docker-compose will make sure to build them in the proper order.  If they have already been built, it will re-use existing images.
  * `docker-compose run --rm rocm-from-src`

## Creating a custom application/development container
The /rocm-terminal sub-directory contains a Dockerfile to build an image specifically built for ROCm software development.  Useful development tools are pre-installed into the container, and it's meant to serve as a starting point for interested developers to customize a dockerfile for their own projects.  To begin, simply:
1. copy the /rocm-terminal sub-directory into a new directory name, such as /my-rocm-terminal
2. open and customize the Dockerfile;  pre-install dependencies and services
3. modify the **docker-compose.yml.template** file and add a new service which prepares a new image
  - copy the 'rocm' target to build a container using the latest ROCm binary release
  - copy the 'rocm-from-src' target to build a container using the latest ROCm source
4. Run `./rocm-setup` script to generate a new **docker-compose.yml**
5. `docker-compose run --rm <new-target-name>`

For illustration, yaml source for an image that builds ROCm from source looks like
```yaml
new-rocm-app:                         # docker-compose target name; was 'rocm-from-src'
  build:
    context: ./my-app                 # new directory used as build context
    dockerfile: Dockerfile
  devices:
    - "/dev/kfd"
  image: rocm/rocm-app               # the name of the generated docker image
  volumes:
    - ~:/usr/local/src/host-home     # add as many host directories to map into container as needed here
  volumes_from:                      # this section imports the binaries built from source
    - roct:ro
    - rocr:ro
    - hcc-lc:ro
    - hcc-hsail:ro
```

### Saving work in a container
Docker containers are typically ephemeral, and are discarded after closing the container with the '**--rm**' flag to `docker run`.  However, there are times when it is desirable to close a container that has arbitrary work in it, and serialize it back into a docker image.  This may be to to create a checkpoint in a long and complicated series of instructions, or it may be desired to share the image with others through a docker registry, such as docker hub.  

```bash
sudo docker ps -a  # Find container of interest
sudo docker commit <container-name> <new-image-name>
sudo docker images # Confirm existence of a new image
```

### rocm-user has root privileges by default
The dockerfile that serves as the 'terminal' creates a non-root user called **rocm-user**.  Since this container is meant to serve as a development environment (and therefore `apt-get` likely needed), the user has been added to the linux sudo group.  In addition, since it is somewhat difficult to set and change passwords in a container (often requiring a rebuild), the password prompt has been disabled for the sudo group.  While this is convenient for development to be able `sudo apt-get install` packages, it does imply *lower security* in the container.  

An option to increase container security:

1.  Eliminate the sudo-nopasswd COPY statement in the dockerfile and replace with
2.  Your own password with `RUN echo 'account:password' | chpasswd`

### Running an application using docker-compose
You can run the new container (and its dependencies) with docker-compose.

```bash
docker-compose run --rm <my-rocm-terminal>  # run as rocm-user
```

| Docker command reference | |
|-----|-----|
| docker-compose | docker compose executable|
| run | sub-command to bring up interactive container |
| --rm | when shutting the container down, delete it |
| -u 0 | override default user with root (uid 0) |
| my-rocm-terminal | application service defined in **docker-compose.yml** |

To shut down ROCm dependencies and clean up
```bash
docker-compose down -v
```
| Docker command reference | |
|-----|-----|
| docker-compose | docker compose executable |
| down | sub-command to shut containers down and remove them |
| -v | clean-up shared volumes |

### Footnotes:
<a name="ROCK">[1]</a> It can be installed into a container, it just doesn't do anything because containers do not go through the traditional boot process.  We actually do provide a container for ROCK-Kernel-Driver, but it not used by the rest of the docker images.  It does provide isolation and a reproducible environment for kernel development.
