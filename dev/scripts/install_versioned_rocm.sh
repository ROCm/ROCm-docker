#!/bin/bash

set -ex

if [ -z $1 ]; then
  echo "Need to provide ROCM_VERSION as first argument" && exit 1
fi

if [[ $1 =~ ^[0-9]+\.[0-9]+$ ]]; then
  ROCM_VERSION=${1}".0"
fi
yum install -y rocm-dev${ROCM_VERSION} rocm-libs${ROCM_VERSION}
