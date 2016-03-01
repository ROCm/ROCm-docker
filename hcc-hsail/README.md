## HCC docker build context
This directory is the docker build context for the HCC ROC compiler with a HSAIL generating backend.  Building the docker container downloads, builds and installs the compiler.

### The host is not modified
| dockerfile | Invoke |
|-----|-----|-----|
| *hcc-hsail-release-dockerfile* | `docker build -f hcc-hsail-release-dockerfile -t roc/hcc-hsail .` |
| *hcc-hsail-debug-dockerfile* | `docker build -f hcc-hsail-debug-dockerfile -t roc/hcc-hsail-debug .` |

Both files contain a dependency on the roc/rocr image.  
The release dockerfile builds the compiler with release flags and deletes the build directories to keep the image smaller
The debug dockerfile builds the compiler with debug flags and keeps retains the build directory

---

Once the docker images has been built, you can run a shell inside of the container with
`docker run -it --rm roc/hcc-hsail`
