#!/usr/bin/env bash

# Series of steps to build layers of containers, each container housing 1 softare component
( cd rock; docker build -f rock-deb-dockerfile -t roc/rock . )
( cd roct; docker build -f roct-thunk-dockerfile -t roc/roct . )
( cd rocr; docker build -f rocr-make-dockerfile -t roc/rocr . )
( cd  hcc; docker build -f hcc-dockerfile -t roc/hcc . )
( cd hcblas; docker build -f hcblas-dockerfile -t roc/hcblas . )
