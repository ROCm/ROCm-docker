FROM ubuntu:24.04  
  
ARG ROCM_VERSION=6.3.1
ARG AMDGPU_VERSION=6.3.60301
ARG JAX_VERSION=0.4.31  
ARG PYTHON_VERSION=cp312-cp312  
  
#Prequisite packages
RUN apt update && apt install -y wget gnupg2 software-properties-common python3-pip python3-venv  
  
#install ROCm  
RUN wget https://repo.radeon.com/amdgpu-install/$ROCM_VERSION/ubuntu/noble/amdgpu-install_$AMDGPU_VERSION-1_all.deb  
RUN apt install -y ./*.deb  
RUN amdgpu-install --usecase=rocm -y && rm *.deb  
  
#virtual environment  
RUN python3 -m venv /opt/venv  
  
#install JAX  
RUN /opt/venv/bin/pip install --upgrade pip  
RUN /opt/venv/bin/pip install https://repo.radeon.com/rocm/manylinux/rocm-rel-6.3/jaxlib-0.4.31-cp312-cp312-manylinux_2_28_x86_64.whl  
  
# Adjust final path
ENV PATH="/opt/venv/bin:$PATH:/opt/rocm/bin/"  
  
# Set the default shell
SHELL ["/bin/bash", "-c"]  
