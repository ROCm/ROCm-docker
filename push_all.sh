ROCM_VERSION=6.4.1

# ubuntu 20.04 base
docker push rocm/dev-ubuntu-20.04:$ROCM_VERSION
docker push rocm/dev-ubuntu-20.04:latest

# ubuntu 22.04 base
docker push rocm/dev-ubuntu-22.04:$ROCM_VERSION
docker push rocm/dev-ubuntu-22.04:latest

## ubuntu 24.04 base
docker push rocm/dev-ubuntu-24.04:$ROCM_VERSION
docker push rocm/dev-ubuntu-24.04:latest

# rocm terminal base 
docker push rocm/rocm-terminal:$ROCM_VERSION
docker push rocm/rocm-terminal:latest

# manylinux2014 base
docker push rocm/dev-manylinux2014_x86_64:$ROCM_VERSION
docker push rocm/dev-manylinux2014_x86_64:latest

# ubuntu20.04 complete
docker push rocm/dev-ubuntu-20.04:$ROCM_VERSION-complete

# ubuntu22.04 complete
docker push rocm/dev-ubuntu-22.04:$ROCM_VERSION-complete

## ubuntu24.04 complete
docker push rocm/dev-ubuntu-24.04:$ROCM_VERSION-complete

# almalinux8 complete
docker push rocm/dev-almalinux-8:$ROCM_VERSION-complete

# almalinux8 complete
docker push rocm/dev-almalinux-8:$ROCM_VERSION