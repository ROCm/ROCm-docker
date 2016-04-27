# ROCm-docker
### Radeon Open Compute Platform for docker
This repository contains a framework for building the various software layers defined in the Radeon Open Compute Platform into portable docker images.  There are docker dependencies to use this framework, which need to be pre-installed on the host.

-  Docker on [Ubuntu systems](https://docs.docker.com/v1.8/installation/ubuntulinux/) or [Fedora systems](https://docs.docker.com/v1.8/installation/fedora/)
-  [Docker-Compose](https://docs.docker.com/compose/install/) as a highly recommended tool

At the root of this repository is the bash script `./roc-setup`
```bash
Usage: ./roc-setup [--master | --develop] [--release | --debug]
Default flags: --master --release

--master) Build dockerfiles from stable master branches; exclusive with --develop
--develop) Build dockerfiles from integration branches; exclusive with --master
--release) Build release containers; minimizes size of docker images; exclusive with --debug
--debug) Build debug containers; symbols generated and build tree intact for debugging; exclusive with --release

Without explicit parameters, `./roc-setup` default flags are --master && --release
```

`./roc-setup` generates Dockerfiles to be consumed by the docker build engine.  Each sub-directory of this repository corresponds to a docker 'build context' responsible for a software layer in the ROCm stack.  After running the script each directory contains a generated 'Dockerfile'.  The parameters to the script control which flavor of the components to build, for instance: debug builds of the /develop branches.

**What are the individual ROCm software components**

| ROC component | |
|-----|-----|
| roct | the kernel thunk library |
| rocr | the runtime |
| hcc-hsail | the compiler that generates HSAIL IL from the backend |
| hcc-lc | the compiler that generates GPU ISA from the backend |

**What repo branches are built with roc-setup flags**

|| --master | --develop |
|------|-----|-----|
|roct| master | dev |
|rocr| master | dev |
|hcc-hsail| master | develop |
|hcc-lc| testing | master |

The ROCm component that can not be used in a docker image is the ROCK-Kernel-Driver<sup>[1](#ROCK)</sup>.  In order for the docker framework to function, **the ROCm kernel must be installed on the host machine.**  This is a design constraint of docker; the linux kernel is not resident in the container.  All containers share the host linux kernel, so the ROCK-Kernel-Driver component must be installed on the host linux kernel.

### Installing ROCK on the host machine.
A [sequence of instructions](https://github.com/RadeonOpenCompute/ROCK-Kernel-Driver#installing-and-configuring-the-kernel) is provided in the ROCK-Kernel-Driver README.

### Docker compose
`./roc-setup` prepares an environment that can be controlled with [Docker Compose](https://docs.docker.com/compose/).  An output of the script is a **docker-compose.yml** file in the root of the repository, which coordinates the relationships between the various ROCm software layers.  Additionally, the  docker-compose.yml file can be extended to easily launch interactive application or development containers built on top of the ROCm software stack.  

### Creating an application/development container
The /rocm-project sub-directory contains a template for a container specifically built for software development.  Common and useful development tools are pre-installed into the container.  To begin, simply:
- copy the /rocm-project sub-directory into a new directory name, such as /my-rocm-project
- open and customize the Dockerfile;  pre-install dependencies and services
- modify the docker-compose.yml.template file to add a new service which launches your new image
  - use the existing rocm-project section as an example
  - add useful host directories to map into the container
- rerun `./roc-setup` script to generate a new **docker-compose.yml**

### Running an application using docker-compose
You run the new container (and its dependencies) with docker-compose.  When the container is fully loaded and running, you will be presented with a root prompt within the container.

```bash
docker-compose run --rm <my-rocm-project>
```

| Docker command reference | |
|-----|-----|
| docker-compose | docker compose executable|
| run | sub-command to bring up interactive container |
| --rm | when shutting the container down, delete it |
| my-rocm-project | application service defined in **docker-compose.yml** |

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
<a name="ROCK">[1]</a> We actually do provide a container for ROCK-Kernel-Driver, but it not used by the rest of the docker images.  It does provide isolation and a reproducible environment for kernel development.
