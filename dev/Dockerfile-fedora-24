# This dockerfile is meant to serve as a rocm base image.  It registers the dnf rocm package repository, and
# installs the rocm-dev package.

FROM fedora:24
LABEL maintainer=kent.knox@amd

# Register the ROCM package repository, and install rocm-dev package
RUN dnf -y update \
  && printf "[remote]\nname=ROCm Repo\nbaseurl=http://repo.radeon.com/rocm/yum/rpm/\nenabled=1\ngpgcheck=0\n" | tee /etc/yum.repos.d/rocm.repo \
  && dnf -y install \
    rocm-dev \
  && dnf -y clean all
