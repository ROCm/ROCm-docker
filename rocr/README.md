## ROCR-Runtime docker build context
This directory is the docker build context of the ROC runtime libraries.  Building the docker container will download, build and install the runtime, isolated in the scope of the docker container.

### The host is not modified

---
| dockerfile | Invoke |
|-----|-----|-----|
| *rocr-deb-dockerfile* | `docker build -f rocr-deb-dockerfile -t roc/rocr .` |
| *rocr-make-release-dockerfile* | `docker build -f rocr-make-release-dockerfile -t roc/rocr .` |
| *rocr-make-debug-dockerfile* | `docker build -f rocr-make-debug-dockerfile -t roc/rocr-debug .` |

All dockerfiles contain a dependency on the roc/roct image to be present.  The `deb` dockerfile installs the runtime through packages contained in the repository.  The `make` dockerfiles compile the code, either with or without debug flags.

---
Once the docker images has been built, you can run a shell inside of the container with:

`docker run -it --rm roc/rocr`
