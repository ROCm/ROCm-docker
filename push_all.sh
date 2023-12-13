ROCM_VERSION=5.7.1

# ubuntu 20.04 base
sudo docker push rocm/dev-ubuntu-20.04:$ROCM_VERSION
sudo docker push rocm/dev-ubuntu-20.04:latest

# ubuntu 22.04 base
sudo docker push rocm/dev-ubuntu-22.04:$ROCM_VERSION
sudo docker push rocm/dev-ubuntu-22.04:latest

# centos base
sudo docker push rocm/dev-centos-7:$ROCM_VERSION
sudo docker push rocm/dev-centos-7:latest

# rocm terminal base 
sudo docker push rocm/rocm-terminal:$ROCM_VERSION
sudo docker push rocm/rocm-terminal:latest

# manylinux2014 base
sudo docker push rocm/dev-manylinux2014_x86_64:$ROCM_VERSION
sudo docker push rocm/dev-manylinux2014_x86_64:latest

# ubuntu20.04 complete
sudo docker push rocm/dev-ubuntu-20.04:$ROCM_VERSION-complete

# ubuntu22.04 complete
sudo docker push rocm/dev-ubuntu-22.04:$ROCM_VERSION-complete

# centos complete
sudo docker push rocm/dev-centos-7:$ROCM_VERSION-complete
