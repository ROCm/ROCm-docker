# ROCP-docker
### Radeon Open Compute Platform for docker
This repository contains dockerfiles for the various software layers defined in the Radeon Open Compute Platform.  Installation instructions for how to install docker on [Ubuntu systems](https://docs.docker.com/v1.8/installation/ubuntulinux/) and [Fedora systems](https://docs.docker.com/v1.8/installation/fedora/) is available.

A bash script `./roc-setup` is provided as a convenience to build the various ROC images.  It builds release variants of the software stack, but debug variants can be built manually.  See the instructions inside of each build context (directory).  After completion, the following images should be present on your system

```bash
kknox@machine:~/src/github/ROCP-docker
[master % u=] $ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
roc/hcblas          latest              8f9f0448139c        2 days ago          2.435 GB
roc/hcc             latest              202ce25086d9        2 days ago          2.43 GB
roc/rocr            latest              b90850967834        3 days ago          1.009 GB
roc/roct            latest              427885fa30bc        3 days ago          933.5 MB
roc/rock            latest              742644f01f50        3 days ago          819.1 MB
ubuntu              14.04.3             3876b81b5a81        3 weeks ago         187.9 MB
```

A roc/rock image is built, which contains the required linux kernel and ROC kernel modules, but the files are isolated into the image and the other software layers on top of it in layers.  *In order for the runtime and compilers to function properly*, **the ROC kernel has to be installed manually on the host machine.**

### Installing ROCK on the host machine.
A [sequence of instructions](https://github.com/RadeonOpenCompute/ROCK-Kernel-Driver#installing-and-configuring-the-kernel) in bash:

1.  `cd /usr/local/src`
2.  `git clone --no-checkout --depth=1 https://github.com/RadeonOpenCompute/ROCK-Kernel-Driver.git`
3.  `cd ROCK-Kernel-Driver`
4.  `git checkout master -- packages/ubuntu`
5.  `dpkg -i packages/ubuntu/*.deb`
6.  `echo "KERNEL==\"kfd\", MODE=\"0666\"" | sudo tee /etc/udev/rules.d/kfd.rules`
7.  `sudo reboot`

### Running an application in the docker stack

If you wish to create a custom docker container for your application, the `hcblas` dockerfile can serve as a template to modify for your own applications.  You run the container, and optionally map host directories (for shared source code, for instance) like so:

```bash
docker run -it --rm -v ~/host-src/project:~/container-src/project user-name/app-name
```

| Docker command reference | |
|-----|-----|
| docker | docker executable|
| run | docker sub-command |
| -it | attach console to container |
| --rm | when exiting container, delete it |
| -v ~/host-src/project:~/container-src/project | map host directory into container |
| user-name/app-name | unique name for container |

### Todo:
1.  Create a proper method to load each software component as a [data-only container](https://docs.docker.com/engine/userguide/containers/dockervolumes/#mount-a-host-directory-as-a-data-volume)
