## HCC docker build context
This directory is the docker build context for the HCC ROC compiler.  Building the docker container downloads, builds and installs the compiler.  This dockerfile is an isolated environment.

### The host is not modified
| dockerfile | Invoke |
|-----|-----|-----|
| *hcc-release-dockerfile* | `docker build -f hcc-release-dockerfile -t roc/hcc .` |
| *hcc-debug-dockerfile* | `docker build -f hcc-debug-dockerfile -t roc/hcc-debug .` |

Both files contains a dependency on the roc/rocr image to be present.  The debug dockerfile builds the compiler with debug flags.

---

Once the docker images has been built, you can run a shell inside of the container with
`docker run -it --rm roc/hcc`
