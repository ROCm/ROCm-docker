## HCC docker build context
This directory is the docker build context for the HCC ROC compiler.  Building the docker container downloads, builds and installs the compiler.  This dockerfile is an isolated environment.

### The host is not modified

One dockerfile is present in this directory
*  hcc-dockerfile

---
**hcc-dockerfile** contains a dependency on the roc/rocr image to be present.

Build with: `docker build -f hcc-dockerfile -t roc/hcc .`

---
Once the docker images has been built, you can run a shell inside of the container with
`docker run -it --rm roc/hcc`
