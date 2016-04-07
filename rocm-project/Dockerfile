# This is a template dockerfile meant to be personalized for application development.
# Copy this dockerfile into a new build context (directory) and modify to taste.

# After a new build context is created, build with
# `docker build -t <user-name>/<project-name> .`

# Run the container to start up a development environment.  Optionally, map host
# directories into the container with -v for development convenience, which is
# especially nice for source code to persist after the container closes.
# The following maps the host directory into the container 'read only'

# 'docker run -it --rm -v [host/directory]:[container/directory]:ro <user-name>/<project-name>'.
# Example: 'docker run -it --rm -v ~/src/my-hcc-project:/root/my-hcc-project:ro kknox/my-hcc-project'.

# The application container can inherit from any other OS container
FROM ubuntu:14.04
MAINTAINER Kent Knox <kent.knox@amd>

# Change WORKPATH to a location where
ENV WORKPATH /opt/my-rocm-project

# The working directory is meant to be where build files are generated
WORKDIR ${WORKPATH}

# Default to a login shell
ENTRYPOINT ["/bin/bash"]
CMD ["-l"]

# Initialize the image to install common and recommended dev tools
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  build-essential \
  clang-3.5 \
  libelf1 \
  curl \
  git \
  gdb \
  valgrind \
  vim-nox \
  cmake-curses-gui && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# The following attempts to create a nice command line developer environment
# 1.  Sets up an enhanced command line dev environment within VIM
# 2.  Aliases GDB to use its native TUI mode by default
RUN curl https://j.mp/spf13-vim3 -L | bash && \
    echo "\nalias gdb='gdb --tui'" >> ~/.bashrc && \
    echo "\nsource /opt/roct/setenv-roct.sh" >> ~/.bashrc && \
    echo "\nsource /opt/hsa/setenv-rocr.sh" >> ~/.bashrc && \
    echo "\nsource /opt/hcc/setenv-hcc.sh" >> ~/.bashrc && \
    mkdir -p ${WORKPATH}
