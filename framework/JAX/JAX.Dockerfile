FROM ubuntu:22.04  
  
# Install prerequisite packages  
RUN apt update && apt install -y wget gnupg2 software-properties-common  
  
# Download and install the AMDGPU package that sets up the repository  
RUN wget http://artifactory-cdn.amd.com/artifactory/list/amdgpu-deb/amdgpu-install-internal_6.3-22.04-1_all.deb \  
    && apt install -y ./amdgpu-install-internal_6.3-22.04-1_all.deb \  
    && rm -f amdgpu-install-internal_6.3-22.04-1_all.deb  
  
# Set up the AMDGPU and ROCm repositories and install ROCm  
RUN amdgpu-repo --amdgpu-build=2074281 --rocm-build=compute-rocm-rel-6.3/20 \  
    && apt update -y \  
    && amdgpu-install -y --usecase=rocm  

# Install JAX Wheel packages  
RUN pip3 install --no-cache-dir https://compute-artifactory.amd.com/artifactory/compute-pytorch-rocm/compute-rocm-rel-6.3/20/jaxlib-0.4.31-cp310-cp310-manylinux_2_28_x86_64.whl 
  
# Adjust final path for ability to use ROCm components  
ENV PATH=$PATH:/opt/rocm/bin/  
