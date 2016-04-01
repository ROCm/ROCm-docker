# ROCm-docker
### Radeon Open Compute Platform for docker
This repository contains dockerfiles for the various software layers defined in the Radeon Open Compute Platform.  Installation instructions for how to install docker on [Ubuntu systems](https://docs.docker.com/v1.8/installation/ubuntulinux/) and [Fedora systems](https://docs.docker.com/v1.8/installation/fedora/) are available.

The root of this repository provides a bash script `./roc-setup` as a convenience to build ROC images.
```bash
Usage: ./roc-setup [--master | --develop] [--release | --debug]
Default flags: --master --release

--master) Build dockerfiles from stable master branches; exclusive with --develop
--develop) Build dockerfiles from integration branches; exclusive with --master
--release) Build release containers; minimizes size of docker images; exclusive with --debug
--debug) Build debug containers; symbols generated and build tree intact for debugging; exclusive with --release
--remove_images) Based on the other flags passed, remove the docker images instead of building them
--dry_run) Print out what would happen with the script, without executing commands

Without explicit parameters, `./roc-setup` default flags are --master && --release
```

The following shows images after building both --master and --develop containers.  All containers are uniquely named to distinguish how they were built.

```bash
kknox@machine:~/src/github/ROCm-docker
[develop *% u=] $ docker images
REPOSITORY                     TAG                 IMAGE ID            CREATED             SIZE
roc/hcc-isa-master-release     latest              d82a7c04f1e4        About an hour ago   1.191 GB
roc/hcc-hsail-master-release   latest              aa4f0543ad43        About an hour ago   1.441 GB
roc/rocr-dev-release           latest              7172446cd45e        About an hour ago   732.5 MB
roc/roct-dev-release           latest              aa711a708039        2 hours ago         666.1 MB
roc/rock-dev                   latest              7bb9dede7b01        2 hours ago         539 MB
roc/hcc-isa-testing-release    latest              bd57b41d79fb        11 hours ago        1.191 GB
roc/rocr-master-release        latest              954dfa5425fc        12 hours ago        732.6 MB
roc/roct-master-release        latest              39399c5cee7d        12 hours ago        666.2 MB
roc/rock-master                latest              c2e70cf58ea7        12 hours ago        539.1 MB
ubuntu                         14.04.3             3876b81b5a81        7 weeks ago         187.9 MB

Container name decoder:  <user-name>/<component>-<branch>-<config>
```

| ROC component | |
|-----|-----|
| hcc-isa | the compiler that generates GPU ISA from the backend |
| hcc-hsail | the compiler that generates HSAIL IL from the backend |
| rocr | the runtime |
| roct | the kernel thunk library |
| rock | the linux kernel with gpu kernel modules |

Even with the existence of these ROC containers, **the ROC kernel must be installed on the host machine.**  This is a design constraint of docker; the linux kernel is not resident in the container.  All containers use the host linux kernel, so the host linux kernel must be prepared to support ROC infrastructure.

### Installing ROCK on the host machine.
A [sequence of instructions](https://github.com/RadeonOpenCompute/ROCK-Kernel-Driver#installing-and-configuring-the-kernel) in bash:

1.  `cd /usr/local/src`
2.  `git clone --no-checkout --depth=1 https://github.com/RadeonOpenCompute/ROCK-Kernel-Driver.git`
3.  `cd ROCK-Kernel-Driver`
4.  `git checkout master -- packages/ubuntu`
5.  `dpkg -i packages/ubuntu/*.deb`
6.  `echo "KERNEL==\"kfd\", MODE=\"0666\"" | sudo tee /etc/udev/rules.d/kfd.rules`
7.  `sudo reboot`

### Creating an application container
After the ROC software stack is built, an application container an be built on top of the ROC stack.  The /hcc-project sub-directory contains a template of a container specifically built for software development.  Common and useful development tools are pre-installed into the container to help.  To begin, simply:
- copy the /hcc-project sub-directory into a new directory name, like /my-roc-project
- open and modify the dockerfile there-in to customize
  - the template derives from roc/hcc-isa-master-release, but could as easily be changed to roc/hcc-hsail-master-release
- an assumption of the application container is a workflow wherein a host directory is mapped into the container
  - the host directory typically will contain source to compile, such as a git repository
    - this makes sure that the source persists after the container closes
  - the generated files from the build should be into the users /home directory or /opt
    - when the container closes, all generated files are cleaned up and forgotten

### Running an application in the docker stack

You run the container, and optionally map host directories (for shared source code, for instance) like so:

```bash
docker run -it --rm -v ~/host/project-src:/root/project-src <user-name>/<app-name>
```

| Docker command reference | |
|-----|-----|
| docker | docker executable|
| run | docker sub-command |
| -it | attach console to container |
| --rm | when exiting container, delete it |
| -v ~/host/project-src:/root/project-src | map host directory into container |
| user-name/app-name | unique name for container |

### Todo:
1.  Create a proper method to load each software component as a [data-only container](https://docs.docker.com/engine/userguide/containers/dockervolumes/#mount-a-host-directory-as-a-data-volume)
