## ROCR-Runtime docker build context
This directory is the docker build context of the ROC runtime libraries.  Building the docker container will download, build and install the runtime, isolated in the scope of the docker container.

### The host is not modified
There are two dockerfiles files present in this directory
*  rocr-deb-dockerfile
*  rocr-make-dockerfile

---
**rocr-deb-dockerfile** will connect to github and clone the ROCR-Runtime repository.  It contains a dependency on the roc/roct image to be present.  This uses the ubuntu packages present in the repository.

Build with: `docker build -f rocr-deb-dockerfile -t roc/rocr .`

---
**rocr-make-dockerfile** will connect to github and clone the ROCR-Runtime repository.  It contains a dependency on the roc/roct image to be present.  This will invoke a 'make' & 'make install' to build the runtime and intall it in the appropriate destination

Build with: `docker build -f rocr-make-dockerfile -t roc/rocr .`

---
Once the docker images has been built, you can run a shell inside of the container with:

`docker run -it --rm roc/rocr`
