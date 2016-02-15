## ROCK-Kernel-Driver docker build context
This directory is the docker build context of the ROC kernel and kernel modules.  Building the docker container will download, optionally build and install the linux kernel with the appropriate kernel modules enabled.  

This dockerfile serves as an example, how-to, or as an isolated environment for kernel hackers, as build files and artifacts are isolated in the scope of the docker container.  

### The host is not modified
---
| file | description |
|-----|-----|-----|
| *rock-deb-dockerfile* | `docker build -f rock-deb-dockerfile -t roc/rock .` |
| *rock-make-dockerfile* | `docker build -f rock-make-dockerfile -t roc/rock .` |
| *rock.config* | used to seed the kernel configuration step |
| *rock.config.diff* | what kernel options changed from the default generated .config |

All dockerfiles contain a dependency on the ubuntu-14.04 image.  The `deb` dockerfile installs the kernel through packages contained in the repository.  The `make` dockerfiles compile the code.
 flags.

---
Once the docker image has been built, you can run a shell inside of the container with:

`docker run -it --rm roc/rock`
