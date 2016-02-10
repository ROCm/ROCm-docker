## ROCK-Kernel-Driver docker build context
This directory is the docker build context of the ROC kernel and kernel modules.  Building the docker container will download, optionally build and install the linux kernel with the appropriate kernel modules enabled.  

This dockerfile serves as an example, how-to, or as an isolated environment for kernel hackers, as build files and artifacts are isolated in the scope of the docker container.  

### The host is not modified
There are two dockerfiles files present in this directory
*  rock-deb-dockerfile
*  rock-make-dockerfile

---
**rock-deb-dockerfile** will connect to github and clone the ROCK-Kernel-Driver repository.  It then unpacks the pre-built .debs that are part of the build tree.  This is the fastest and tested way to install the amdkfd and amdgpu components

Build with: `docker build -f rock-deb-dockerfile -t roc/rock .`

---
**rock-make-dockerfile** also connects to github and clones the ROCK-Kernel-Driver repository.  Instead of using the pre-built debian packages, it build a new kernel with the amdkfd and amdgpu kernel modules enabled.  

Build with: `docker build -f rock-make-dockerfile -t roc/rock .`

---
Once the docker images has been built, you can run a shell inside of the container with:

`docker run -it --rm roc/rock`

**rock.config** is used to seed the kernel configuration step, turning on boltzmann kernel modules in the **rock-make-dockerfile**

**rock.config.diff** shows what kernel options changed from the default generated .config
