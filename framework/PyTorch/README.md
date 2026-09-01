# PyTorch ROCm runtime image

This build reproduces the public ROCm 10.0 / PyTorch 2.12 `device-all` image using
the multi-architecture ROCm wheel index.

## Verified size reduction

Compared with
`rocm/pytorch:rocm10.0_ubuntu24.04_py3.12_pytorch_release_2.12.0`:

| Measurement | Published image | Cache-free build | Reduction |
| --- | ---: | ---: | ---: |
| Docker unpacked size | 30,760,393,878 B | 20,952,333,377 B | 9,808,060,501 B (31.89%) |
| Gzip-compressed `docker save` | 20,620,366,768 B | 10,840,075,400 B | 9,780,291,368 B (47.43%) |
| `/root/.cache/pip` | 9,884,192,097 B | 62,120,620 B | 9,822,071,477 B (99.37%) |

Both images contain 146 device-code `.kpack` files and report PyTorch
`2.12.0+rocm10.0.0`. The rebuilt image also passed a 2048x2048 GPU matrix
multiplication on an MI325 host.

Build it from the repository root:

```bash
docker build \
  --file framework/PyTorch/Dockerfile \
  --tag rocm/pytorch:rocm10-pytorch2.12-no-pip-cache \
  framework/PyTorch
```

The wheel installer disables pip's HTTP and wheel caches. Device wheels are
already installed into the virtual environment, so retaining their downloaded
archives duplicates several gigabytes without affecting runtime behavior.

To build for only one GPU architecture, override `AMDGPU_FAMILY`, for example:

```bash
docker build \
  --build-arg AMDGPU_FAMILY=gfx942 \
  --file framework/PyTorch/Dockerfile \
  --tag rocm/pytorch:rocm10-pytorch2.12-gfx942 \
  framework/PyTorch
```
