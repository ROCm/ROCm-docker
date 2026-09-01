FROM ubuntu:24.04

ARG PYTHON_VERSION=3.12

COPY scripts/install_rocm_deps.sh /tmp/
COPY scripts/install_python.sh /tmp/
RUN chmod +x /tmp/install_rocm_deps.sh /tmp/install_python.sh && \
    /tmp/install_rocm_deps.sh && \
    /tmp/install_python.sh "${PYTHON_VERSION}"

RUN python${PYTHON_VERSION} -m venv /opt/venv && \
    /opt/venv/bin/python -m pip install --upgrade pip && \
    /opt/venv/bin/python -m pip install --upgrade setuptools

ENV VIRTUAL_ENV=/opt/venv \
    PATH=/opt/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

ARG ROCM_VERSION=10.0.0
ARG AMDGPU_FAMILY=device-all
ARG RELEASE_TYPE=nightly
ARG INDEX_URL=https://stable.repo.amd.com/rocm/whl-next
ARG EXTRA_INDEX_URL=
ARG PIN_EXPLICIT_VERSIONS=true
ARG TORCH_VERSION=2.12.0+rocm10.0.0
ARG TORCHAUDIO_VERSION=2.11.0+rocm10.0.0
ARG TORCHVISION_VERSION=0.27.0+rocm10.0.0
ARG APEX_VERSION=1.12.0+rocm10.0.0
ARG TRITON_VERSION=

LABEL image.title="PyTorch + ROCm runtime image (NPI)" \
      image.version="${ROCM_VERSION}" \
      npi.amdgpu_family="${AMDGPU_FAMILY}" \
      npi.python_version="${PYTHON_VERSION}" \
      npi.rocm_version="${ROCM_VERSION}"

COPY scripts/install_pytorch_wheels.py /tmp/
COPY scripts/detect_device_arches.py /tmp/

RUN /opt/venv/bin/python -m pip install \
        "cxxfilt>=0.2.0" \
        "tqdm>=4.28.1" \
        numpy \
        "PyYAML>=5.1" \
        "pytest>=3.5.1" \
        "packaging>=14.0" \
        "matplotlib>=3.8" \
        "pandas>=2.2.2" \
        py-cpuinfo \
        build \
        ninja \
        wheel

RUN set -eu; \
    PIN_EXPLICIT_FLAG=""; \
    if [ "${PIN_EXPLICIT_VERSIONS}" = "true" ]; then PIN_EXPLICIT_FLAG="--pin-explicit-versions"; fi; \
    /opt/venv/bin/python /tmp/install_pytorch_wheels.py \
        --no-break-system-packages \
        --skip-verify \
        --device-targets "${AMDGPU_FAMILY}" \
        --index-url "${INDEX_URL}" \
        ${EXTRA_INDEX_URL:+--extra-index-url "${EXTRA_INDEX_URL}"} \
        --amdgpu-family "${AMDGPU_FAMILY}" \
        ${ROCM_VERSION:+--rocm-version "${ROCM_VERSION}"} \
        ${PIN_EXPLICIT_FLAG} \
        ${TORCH_VERSION:+--torch-version "${TORCH_VERSION}"} \
        ${TORCHAUDIO_VERSION:+--torchaudio-version "${TORCHAUDIO_VERSION}"} \
        ${TORCHVISION_VERSION:+--torchvision-version "${TORCHVISION_VERSION}"} \
        ${APEX_VERSION:+--apex-version "${APEX_VERSION}"} \
        ${TRITON_VERSION:+--triton-version "${TRITON_VERSION}"}

RUN /opt/venv/bin/python -c "import torch; import torchaudio; import torchvision; import apex; import triton; print('torch', torch.__version__); print('ROCm/HIP', torch.version.hip)"

CMD ["/bin/bash"]
