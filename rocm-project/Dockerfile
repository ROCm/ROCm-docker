# This dockerfile meant to be personalized for application development.
# Copy this dockerfile into a new build context (directory) and modify to taste.

# It is recommended to control docker containers through 'docker-compose' https://docs.docker.com/compose/
# Docker compose depends on a .yml file to control container sets
# roc-setup.sh can generate a useful docker-compose .yml file
# `docker-compose run --rm <rocm-project>`

# If running the container manually through the docker command-line, the following is an example
# 'docker run -it --rm -v [host/directory]:[container/directory]:ro <user-name>/<project-name>'.

# The application container can inherit from any other OS container
FROM ubuntu:14.04
MAINTAINER Kent Knox <kent.knox@amd>

# Default to a login shell
ENTRYPOINT ["/bin/bash"]
CMD ["-l"]

# The following imports a key to the external AMD packages repository to make it trusted
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y curl && \
    curl -sL http://packages.amd.com/rocm/apt/debian/rocm.gpg.key | apt-key add - && \
    sh -c 'echo deb [arch=amd64] http://packages.amd.com/rocm/apt/debian/ trusty main > /etc/apt/sources.list.d/rocm.list'

# Initialize the image to install recommended dev tools and ROCm packages
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  build-essential \
  clang-3.5 \
  libelf1 \
  rocm \
  git \
  gdb \
  valgrind \
  vim-nox \
  cmake-curses-gui && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# This is meant to be an interactive container; create a non-root user
RUN useradd --create-home --shell /bin/bash rocm-user
USER rocm-user
WORKDIR /home/rocm-user

# The following attempts to create a nice command line developer environment
# 1.  Sets up an enhanced command line dev environment within VIM
# 2.  Aliases GDB to use its native TUI mode by default
RUN curl -sL https://j.mp/spf13-vim3 | bash && \
    echo "\n PATH=${PATH}:/opt/rocm/bin\n" >> ~/.bashrc && \
    echo "alias gdb='gdb --tui'\n" >> ~/.bashrc
