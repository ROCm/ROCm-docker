ROCM_VERSION=5.0
AMDGPU_VERSION=21.50
cp -r scripts rocm-terminal
cp -r scripts dev

# build rocm-terminal
cd rocm-terminal/
sudo docker build . -f Dockerfile -t rocm/rocm-terminal:$ROCM_VERSION --no-cache --build-arg=ROCM_VERSION=$ROCM_VERSION --build-arg=AMDGPU_VERSION=$AMDGPU_VERSION
sudo docker build . -f Dockerfile.post-install --build-arg=base_image=rocm/rocm-terminal:$ROCM_VERSION -t rocm/rocm-terminal:$ROCM_VERSION
sudo docker tag rocm/rocm-terminal:$ROCM_VERSION rocm/rocm-terminal:latest

#build dev dockers
cd ../dev
#centos-7
sudo docker build . -f Dockerfile-centos-7 -t rocm/dev-centos-7:$ROCM_VERSION --no-cache --build-arg=ROCM_VERSION=$ROCM_VERSION  --build-arg=AMDGPU_VERSION=$AMDGPU_VERSION
sudo docker build . -f Dockerfile.post-install-centos --build-arg=base_image=rocm/dev-centos-7:$ROCM_VERSION -t rocm/dev-centos-7:$ROCM_VERSION
sudo docker tag rocm/dev-centos-7:$ROCM_VERSION rocm/dev-centos-7:latest

#ubuntu20.04
sudo docker build . -f Dockerfile-ubuntu-20.04 -t rocm/dev-ubuntu-20.04:$ROCM_VERSION --no-cache --build-arg=ROCM_VERSION=$ROCM_VERSION  --build-arg=AMDGPU_VERSION=$AMDGPU_VERSION
sudo docker build . -f Dockerfile.post-install --build-arg=base_image=rocm/dev-ubuntu-20.04:$ROCM_VERSION -t rocm/dev-ubuntu-20.04:$ROCM_VERSION
sudo docker tag rocm/dev-ubuntu-20.04:$ROCM_VERSION rocm/dev-ubuntu-20.04:latest

#ubuntu18.04
sudo docker build . -f Dockerfile-ubuntu-18.04 -t rocm/dev-ubuntu-18.04:$ROCM_VERSION --no-cache --build-arg=ROCM_VERSION=$ROCM_VERSION --build-arg=AMDGPU_VERSION=$AMDGPU_VERSION
sudo docker build . -f Dockerfile.post-install --build-arg=base_image=rocm/dev-ubuntu-18.04:$ROCM_VERSION -t rocm/dev-ubuntu-18.04:$ROCM_VERSION
sudo docker tag rocm/dev-ubuntu-18.04:$ROCM_VERSION rocm/dev-ubuntu-18.04:latest

#ubuntu18.04 complete
sudo docker build . -f Dockerfile-ubuntu-18.04-complete -t rocm/dev-ubuntu-18.04:$ROCM_VERSION-complete --no-cache --build-arg=ROCM_VERSION=$ROCM_VERSION --build-arg=AMDGPU_VERSION=$AMDGPU_VERSION
sudo docker build . -f Dockerfile.post-install --build-arg=base_image=rocm/dev-ubuntu-18.04:$ROCM_VERSION-complete -t rocm/dev-ubuntu-18.04:$ROCM_VERSION-complete

#ubuntu20.04 complete
sudo docker build . -f Dockerfile-ubuntu-20.04-complete -t rocm/dev-ubuntu-20.04:$ROCM_VERSION-complete --no-cache --build-arg=ROCM_VERSION=$ROCM_VERSION --build-arg=AMDGPU_VERSION=$AMDGPU_VERSION
sudo docker build . -f Dockerfile.post-install --build-arg=base_image=rocm/dev-ubuntu-20.04:$ROCM_VERSION-complete -t rocm/dev-ubuntu-20.04:$ROCM_VERSION-complete
