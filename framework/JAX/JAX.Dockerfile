FROM ubuntu:24.04

ARG ROCM_VERSION=6.3
ARG AMDGPU_VERSION=6.3.60300
ARG JAX_VERSION=0.4.31
ARG PYTHON_VERSION=cp312-cp312

#Prequisite packages to begin getting files
RUN apt update && apt install -y wget gnupg2 software-properties-common  

#Aquire and install ROCm
RUN wget https://repo.radeon.com/amdgpu-install/$ROCM_VERSION/ubuntu/jammy/amdgpu-install_$AMDGPU_VERSION-1_all.deb
RUN apt install -y ./*.deb
RUN amdgpu-install --usecase=rocm -y && rm *.deb

##Install JAX
RUN pip3 install https://repo.radeon.com/rocm/manylinux/rocm-rel-$ROCM_VERSION/jaxlib-$JAX_VERSION-$PYTHON_VERSION-manylinux_2_28_x86_64.whl

##Adjust final path for ability to use rocm components
ENV PATH=$PATH:/opt/rocm/bin/
