## hcBLAS docker build context
This directory is the docker build context for the hcBLAS library.  Building the docker container downloads, builds and installs the library.  This dockerfile is an isolated environment.

### The host is not modified

| dockerfile | Invoke |
|-----|-----|-----|
| *hcblas-release-dockerfile* | `docker build -f hcblas-release-dockerfile -t roc/hcblas .` |
| *hcblas-debug-dockerfile* | `docker build -f hcblas-debug-dockerfile -t roc/hcblas-debug .` |

Both files contains a dependency on the roc/rocr image to be present.  The debug dockerfile builds the compiler with debug flags.

---
Once the docker images has been built, you can run a shell inside of the container with
`docker run -it --rm roc/hcblas`
