# This dockerfile is meant to be personalized, and serves as a template and demonstration.
# Modify it directly, but it is recommended to copy this dockerfile into a new build context (directory),
# modify to taste and modify docker-compose.yml.template to build and run it.

# It is recommended to control docker containers through 'docker-compose' https://docs.docker.com/compose/
# Docker compose depends on a .yml file to control container sets
# rocm-setup.sh can generate a useful docker-compose .yml file
# `docker-compose run --rm <rocm-terminal>`

# If it is desired to run the container manually through the docker command-line, the following is an example
# 'docker run -it --rm -v [host/directory]:[container/directory]:ro <user-name>/<project-name>'.

FROM ubuntu:24.04
LABEL maintainer=dl.mlsedevops@amd.com

# Initialize the image
# Modify to pre-install dev tools and ROCm packages
ARG ROCM_VERSION=6.2
ARG AMDGPU_VERSION=6.2

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates curl gnupg && \
  curl -sL http://repo.radeon.com/rocm/rocm.gpg.key | gpg --dearmor | dd of=/etc/apt/keyrings/rocm.gpg && \
  printf "deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/$ROCM_VERSION/ noble main" | tee --append /etc/apt/sources.list.d/rocm.list \
  && printf "deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/amdgpu/$AMDGPU_VERSION/ubuntu noble main" | tee /etc/apt/sources.list.d/amdgpu.list && \
  apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  sudo \
  libelf1 \
  libnuma-dev \
  build-essential \
  git \
  vim-nox \
  cmake-curses-gui \
  kmod \
  file \
  python3-dev \
  python3-venv && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

#need to add back in
#rocm-dev && \

RUN  groupadd -g 109 render

# Grant members of 'sudo' group passwordless privileges
# Comment out to require sudo
COPY sudo-nopasswd /etc/sudoers.d/sudo-nopasswd

# This is meant to be used as an interactive developer container
# Create user rocm-user as member of sudo group
# Append /opt/rocm/bin to the system PATH variable
RUN useradd --create-home -G sudo,video,render --shell /bin/bash rocm-user
#    sed --in-place=.rocm-backup 's|^\(PATH=.*\)"$|\1:/opt/rocm/bin"|' /etc/environment

USER rocm-user
WORKDIR /home/rocm-user
ENV PATH "${PATH}:/opt/rocm/bin"

RUN python3 -m venv /home/rocm-user/venv && \
  printf "source /home/rocm-user/venv/bin/activate"  | tee --append /home/rocm-user/.bashrc
  
# The following are optional enhancements for the command-line experience
# Uncomment the following to install a pre-configured vim environment based on http://vim.spf13.com/
# 1.  Sets up an enhanced command line dev environment within VIM
# 2.  Aliases GDB to enable TUI mode by default
#RUN curl -sL https://j.mp/spf13-vim3 | bash && \
#    echo "alias gdb='gdb --tui'\n" >> ~/.bashrc

# Default to a login shell
CMD ["bash", "-l"]
