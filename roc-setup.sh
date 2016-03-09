#!/usr/bin/env bash

# Set reasonable defaults for dockerfile builds
# Default: --master, --release

# Build dockerfiles from more stable master branches; exclusive with --develop
build_master=1

# Build dockerfiles from newer develop branches; exclusive with --master
build_develop=

# Build release binaries; this cleans up and deletes the build to minimize docker image; exclusive with --debug
build_release=1

# Build debug binaries; this leaves build tree intact for greater debugging; exclusive with --release
build_debug=

function display_help()
{
  echo "Building ROC docker images from templates"
  echo "Usage: ./roc-setup [--master | --develop] [--release | --debug]"
  echo "--master) Build dockerfiles from stable master branches; exclusive with --develop"
  echo "--develop) Build dockerfiles from integration branches; exclusive with --master"
  echo "--release) Build release containers; minimizes size of docker images; exclusive with --debug"
  echo "--debug) Build debug containers; symbols generated and build tree intact for debugging; exclusive with --release"
}

while :; do
  case $1 in
    --master)
      build_master=1
      build_develop=
      ;;
    --develop)
      build_master=
      build_develop=1
      ;;
    --release)
      build_release=1
      build_debug=
      ;;
    --debug)
      build_release=
      build_debug=1
      ;;
    -h|--help)
      display_help
      exit
      ;;
    *)
      break
  esac

  shift
done

# hcc-hsail does not have a 'standard' develop branch per-se
repo_branch_hcc_hsail="master"

# hcc-isa conforms to a non git-flow branch naming scheme
repo_branch_hcc_isa=

repo_branch=
if [ -n "${build_master}" ]; then
  repo_branch="master"
  repo_branch_hcc_isa="testing"
else
  repo_branch="dev"
  repo_branch_hcc_isa="master"
fi

build_config=
if [ -n "${build_release}" ]; then
  build_config="Release"
else
  build_config="Debug"
fi

# The comma operator in ${build_config} makes the first letter lower case
rock_name="roc/rock-${repo_branch}"
roct_name="roc/roct-${repo_branch}-${build_config,}"
rocr_name="roc/rocr-${repo_branch}-${build_config,}"
hcc_hsail_name="roc/hcc-hsail-${repo_branch_hcc_hsail}-${build_config,}"
hcc_isa_name="roc/hcc-isa-${repo_branch_hcc_isa}-${build_config,}"

rock_docker_build="cat rock/rock-deb-dockerfile.template | sed s/~~branch~~/${repo_branch}/g -"
roct_docker_build="cat roct/roct-thunk-dockerfile.template | sed s/~~branch~~/${repo_branch}/g - | sed s#~~rock_container~~#${rock_name}#g -"
rocr_docker_build="cat rocr/rocr-make-dockerfile.template | sed s/~~branch~~/${repo_branch}/g - | sed s#~~roct_container~~#${roct_name}#g -"
hcc_hsail_docker_build="cat hcc-hsail/hcc-hsail-dockerfile.template | sed s/~~branch~~/${repo_branch_hcc_hsail}/g - | sed s#~~rocr_container~~#${rocr_name}#g -"
hcc_isa_docker_build="cat hcc-isa/hcc-isa-dockerfile.template | sed s/~~branch~~/${repo_branch_hcc_isa}/g - | sed s#~~rocr_container~~#${rocr_name}#g -"

# ROCT customization
if [ -n "${build_release}" ]; then
  roct_docker_build="${roct_docker_build} | sed s/~~config~~/REL\=1/g -"
else
  roct_docker_build="${roct_docker_build} | sed s/~~config~~//g -"
fi

rocr_docker_build="${rocr_docker_build} | sed s/~~config~~/${build_config}/g -"
hcc_hsail_docker_build="${hcc_hsail_docker_build} | sed s/~~config~~/${build_config}/g -"
hcc_isa_docker_build="${hcc_isa_docker_build} | sed s/~~config~~/${build_config}/g -"

# Uncomment below to debug individual dockerfile templates; generated dockerfile is printed to screen
#eval ${rock_docker_build}
#eval ${roct_docker_build}
#eval ${rocr_docker_build}
#eval ${hcc_hsail_docker_build}
#eval ${hcc_isa_docker_build}

rock_docker_build="${rock_docker_build} | docker build -t ${rock_name} -"
roct_docker_build="${roct_docker_build} | docker build -t ${roct_name} -"
rocr_docker_build="${rocr_docker_build} | docker build -t ${rocr_name} -"
hcc_hsail_docker_build="${hcc_hsail_docker_build} | docker build -t ${hcc_hsail_name} -"
hcc_isa_docker_build="${hcc_isa_docker_build} | docker build -t ${hcc_isa_name} -"

# These statements below generate the actual docker images
eval ${rock_docker_build}
eval ${roct_docker_build}
eval ${rocr_docker_build}
eval ${hcc_hsail_docker_build}
eval ${hcc_isa_docker_build}
