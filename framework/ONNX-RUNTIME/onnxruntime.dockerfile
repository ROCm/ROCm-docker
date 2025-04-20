FROM ubuntu:22.04

ARG ROCM_VERSION=6.4
ARG AMDGPU_VERSION=6.4.60400
ARG ONNX_VERSION=1.21.0
ARG triton_version=3.2.0
ARG torchvision_version=0.21.0
ARG torch_version=2.6.0
ARG PYTHON_VERSION=cp310-cp310
ARG PREFIX=/usr/local

#Prequisite packages to begin getting files
RUN apt update && apt install -y wget

#Aquire and install ROCm
RUN wget https://repo.radeon.com/amdgpu-install/$ROCM_VERSION/ubuntu/jammy/amdgpu-install_$AMDGPU_VERSION-1_all.deb
RUN apt install -y ./*.deb
RUN amdgpu-install --usecase=rocm -y && rm *.deb

##Install MIGraphX from package manager
RUN apt install -y migraphx

##Pieces for Onnxruntime for ROCm and MIGraphX Execution Provider Support

RUN pip3 install https://repo.radeon.com/rocm/manylinux/rocm-rel-$ROCM_VERSION/onnxruntime_rocm-$ONNX_VERSION-$PYTHON_VERSION-linux_x86_64.whl

##Pieces for pytorch
RUN pip3 install https://repo.radeon.com/rocm/manylinux/rocm-rel-$ROCM_VERSION/pytorch_triton_rocm-$triton_version%2Brocm$ROCM_VERSION.*-$PYTHON_VERSION-linux_x86_64.whl
RUN pip3 install https://repo.radeon.com/rocm/manylinux/rocm-rel-$ROCM_VERSION/torch-$torch_version+rocm$ROCM_VERSION-$PYTHON_VERSION-linux_x86_64.whl
RUN pip3 install https://repo.radeon.com/rocm/manylinux/rocm-rel-$ROCM_VERSION/torchvision-$torchvision_version+rocm$ROCM_VERSION-PYTHON_VERSION-linux_x86_64.whl

##Adjust final path for ability to use rocm components
ENV PATH=$PATH:/opt/rocm/bin/

