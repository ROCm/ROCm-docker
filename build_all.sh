ROCM_VERSION=6.2.2
AMDGPU_VERSION=6.2.2

cp -r scripts rocm-terminal
cp -r scripts dev

# build rocm-terminal
cd rocm-terminal/
sudo docker build . -f Dockerfile -t rocm/rocm-terminal:$ROCM_VERSION --build-arg=ROCM_VERSION=$ROCM_VERSION --build-arg=AMDGPU_VERSION=$AMDGPU_VERSION
sudo docker tag rocm/rocm-terminal:$ROCM_VERSION rocm/rocm-terminal:latest

# build dev dockers
cd ../dev
# centos-7
sudo docker build . -f Dockerfile-centos-7 -t rocm/dev-centos-7:$ROCM_VERSION --build-arg=ROCM_VERSION=$ROCM_VERSION  --build-arg=AMDGPU_VERSION=$AMDGPU_VERSION
sudo docker tag rocm/dev-centos-7:$ROCM_VERSION rocm/dev-centos-7:latest

# centos-7 complete
sudo docker build . -f Dockerfile-centos-7-complete -t rocm/dev-centos-7:$ROCM_VERSION-complete --build-arg=ROCM_VERSION=$ROCM_VERSION  --build-arg=AMDGPU_VERSION=$AMDGPU_VERSION

# manylinux2014_x86_64
sudo docker build . -f Dockerfile-manylinux2014_x86_64 -t rocm/dev-manylinux2014_x86_64:$ROCM_VERSION --build-arg=ROCM_VERSION=$ROCM_VERSION  --build-arg=AMDGPU_VERSION=$AMDGPU_VERSION
sudo docker tag rocm/dev-manylinux2014_x86_64:$ROCM_VERSION rocm/dev-manylinux2014_x86_64:latest

# ubuntu20.04
sudo docker build . -f Dockerfile-ubuntu-20.04 -t rocm/dev-ubuntu-20.04:$ROCM_VERSION --build-arg=ROCM_VERSION=$ROCM_VERSION  --build-arg=AMDGPU_VERSION=$AMDGPU_VERSION
sudo docker tag rocm/dev-ubuntu-20.04:$ROCM_VERSION rocm/dev-ubuntu-20.04:latest

# ubuntu20.04 complete
sudo docker build . -f Dockerfile-ubuntu-20.04-complete -t rocm/dev-ubuntu-20.04:$ROCM_VERSION-complete --build-arg=ROCM_VERSION=$ROCM_VERSION --build-arg=AMDGPU_VERSION=$AMDGPU_VERSION

# ubuntu22.04
sudo docker build . -f Dockerfile-ubuntu-22.04 -t rocm/dev-ubuntu-22.04:$ROCM_VERSION  --build-arg=ROCM_VERSION=$ROCM_VERSION --build-arg=AMDGPU_VERSION=$AMDGPU_VERSION --build-arg=APT_PREF="Package: *\nPin: release o=repo.radeon.com\nPin-Priority: 600"
sudo docker tag rocm/dev-ubuntu-22.04:$ROCM_VERSION rocm/dev-ubuntu-22.04:latest

# ubuntu22.04 complete
sudo docker build . -f Dockerfile-ubuntu-22.04-complete -t rocm/dev-ubuntu-22.04:$ROCM_VERSION-complete --build-arg=ROCM_VERSION=$ROCM_VERSION --build-arg=AMDGPU_VERSION=$AMDGPU_VERSION --build-arg=APT_PREF="Package: *\nPin: release o=repo.radeon.com\nPin-Priority: 600"

# almalinux8 complete (for manylinux2_28 builds)
sudo docker build . -f Dockerfile-almalinux-8-complete -t rocm/dev-almalinux-8:$ROCM_VERSION-complete --build-arg=ROCM_VERSION=$ROCM_VERSION --build-arg=AMDGPU_VERSION=$AMDGPU_VERSION

## ubuntu24.04
sudo docker build . -f Dockerfile-ubuntu-24.04 -t rocm/dev-ubuntu-24.04:$ROCM_VERSION  --build-arg=ROCM_VERSION=$ROCM_VERSION --build-arg=AMDGPU_VERSION=$AMDGPU_VERSION --build-arg=APT_PREF="Package: *\nPin: release o=repo.radeon.com\nPin-Priority: 600"
sudo docker tag rocm/dev-ubuntu-24.04:$ROCM_VERSION rocm/dev-ubuntu-24.04:latest

## ubuntu24.04 complete
sudo docker build . -f Dockerfile-ubuntu-24.04-complete -t rocm/dev-ubuntu-24.04:$ROCM_VERSION-complete --build-arg=ROCM_VERSION=$ROCM_VERSION --build-arg=AMDGPU_VERSION=$AMDGPU_VERSION
