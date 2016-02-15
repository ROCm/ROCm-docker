## ROCT-Thunk-Interface docker build context
This directory is the docker build context of the ROC thunk interface.  Building the docker container downloads, builds and installs the radeon compute user-mode API interfaces.

This dockerfile serves as an example, how-to, or as an isolated environment for kernel hackers, as build files and artifacts are isolated in the scope of the docker container.  

### The host is not modified

---
| dockerfile | Invoke |
|-----|-----|-----|
| *roct-thunk-release-dockerfile* | `docker build -f roct-thunk-release-dockerfile -t roc/roct .` |
| *roct-thunk-debug-dockerfile* | `docker build -f roct-thunk-release-dockerfile -t roc/roct .` |

 Both files contains a dependency on the roc/rock image to be present.  The debug dockerfile builds the thunk layer with debug flags.

---
Once the docker images has been built, you can run a shell inside of the container with
`docker run -it --rm roc/roct`
