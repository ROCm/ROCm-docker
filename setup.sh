#!/usr/bin/env bash
# #################################################
# Copyright (c) 2016 Advanced Micro Devices, Inc.
# #################################################
# Author: Kent Knox

# #################################################
# Pre-requisites check
# #################################################

# check if curl is installed
type curl > /dev/null
if [[ $? -ne 0 ]]; then
  echo "This script uses curl to download components; try installing with package manager";
  exit 2
fi

# check if getopt command is installed
type getopt > /dev/null
if [[ $? -ne 0 ]]; then
  echo "This script uses getopt to parse arguments; try installing the util-linux package";
  exit 1
fi

# lsb-release file describes the system
if [[ ! -e "/etc/lsb-release" ]]; then
  echo "This script depends on the /etc/lsb-release file"
  exit 2
fi
source /etc/lsb-release

if [[ ${DISTRIB_CODENAME} != trusty ]] && [[ ${DISTRIB_CODENAME} != xenial ]]; then
  echo "This script only validated with Ubuntu trusty [14.04] or xenial [16.04]"
  exit 2
fi

# #################################################
# helper functions
# #################################################
function display_help()
{
  echo "Building ROC docker images from templates"
  echo "Usage: ./setup [--debian] ([--build] [--master | --develop] [--release | --debug] )"
  echo "Default flags: --debian"
  echo ""
  echo "    [-h|--help] prints this help message"
  echo "    [--debian] install binary packages from packages.amd.com; exclusive with --build"
  echo "    [--build] build rocm packages from source; defaults to master branch and release build"
  echo "    [--master] Build dockerfiles from stable master branches; exclusive with --develop"
  echo "    [--develop] Build dockerfiles from integration branches; exclusive with --master"
  echo "    [--release] Build release containers; minimizes size of docker images; exclusive with --debug"
  echo "    [--debug] Build debug containers; symbols generated and build tree intact for debugging; exclusive with --release"
}

# #################################################
# global variables
# #################################################
install_deb=true
build_src=false

build_master=true
build_develop=false

build_release=true
build_debug=false

# #################################################
# Parameter parsing
# #################################################

# check if we have a modern version of getopt that can handle whitespace and long parameters
getopt -T
if [[ $? -eq 4 ]]; then
  GETOPT_PARSE=$(getopt --name "${0}" --longoptions help,debian,build,master,develop,release,debug --options h -- "$@")
else
  echo "Legacy getopt not handled"
  exit 1
fi

if [[ $? -ne 0 ]]; then
  echo "getopt invocation failed; could not parse the command line";
  exit 1
fi

eval set -- "${GETOPT_PARSE}"

while true; do
  case "${1}" in
    -h|--help)
      display_help
      exit 0
      ;;
    --debian)
      install_deb=true
      build_src=false
      shift ;;
    --build)
      install_deb=false
      build_src=true
      shift ;;
    --master)
      build_master=true
      build_develop=false
      shift ;;
    --develop)
      build_master=false
      build_develop=true
      shift ;;
    --release)
      build_release=true
      build_debug=false
      shift ;;
    --debug)
      build_release=false
      build_debug=true
      shift ;;
    --) shift ; break ;;
    *)  echo "getopt parsing error";
        exit 2
        ;;
  esac
done

if [[ "${install_deb}" == true ]] && [[ "${build_src}" == true ]]; then
    echo "--debian is mutually exlusive with --build"
    exit 2
fi

# #################################################
# Start of main
# #################################################

# hcc-lc conforms to a non git-flow naming scheme, 'master' changes the most
export repo_branch="master"
export repo_branch_hcc_lc=
export repo_branch_hcc_hsail=
export repo_branch_rocr="master"

if [ -n "${build_master}" ]; then
  repo_branch_hcc_hsail="master"
  repo_branch_hcc_lc="clang_tot_upgrade"
else
  repo_branch_hcc_hsail="master"
  repo_branch_hcc_lc="clang_tot_upgrade"
fi

export build_config=
export build_config_roct=
export roct_cleanup=
export rocr_cleanup=
export hcc_hsail_cleanup=
export hcc_lc_cleanup=
export rock_name=
export roct_name=
export rocr_name=
export hcc_hsail_name=
export hcc_lc_name=

rocm_prefix="rocm/"
if [ -n "${build_release}" ]; then
  build_config='Release'

  rock_name="${rocm_prefix}rock-${repo_branch}"
  roct_name="${rocm_prefix}roct-${repo_branch}"
  rocr_name="${rocm_prefix}rocr-${repo_branch_rocr}"
  hcc_hsail_name="${rocm_prefix}hcc-hsail-${repo_branch_hcc_hsail}"
  hcc_lc_name="${rocm_prefix}hcc-lc-${repo_branch_hcc_lc}"

  # Custom commands to clean up build directories for each component
  # This is to keep release images as small as possible
  build_config_roct='REL=1'
  roct_cleanup='cd ~ && rm -rf ${HSATHK_BUILD_PATH} &&'
  rocr_cleanup='cd ~ && rm -rf ${ROCR_BUILD_PATH} &&'
  hcc_hsail_cleanup='cd ~ && rm -rf ${HCC_BUILD_PATH} &&'
  hcc_lc_cleanup='cd ~ && rm -rf ${HCC_BUILD_PATH} &&'
else
  build_config='Debug'

  # For debug builds, name the images as 'debug'
  # The comma operator in ${build_config} makes the first letter lower case
  rock_name="${rocm_prefix}rock-${repo_branch}"
  roct_name="${rocm_prefix}roct-${repo_branch}-${build_config,}"
  rocr_name="${rocm_prefix}rocr-${repo_branch_rocr}-${build_config,}"
  hcc_hsail_name="${rocm_prefix}hcc-hsail-${repo_branch_hcc_hsail}-${build_config,}"
  hcc_lc_name="${rocm_prefix}hcc-lc-${repo_branch_hcc_lc}-${build_config,}"
fi

export rocm_volume='/opt/rocm/'
export rock_volume="${rocm_volume}rock/"
export roct_volume="${rocm_volume}libhsakmt/"
export rocr_volume="${rocm_volume}hsa/"
export hcc_hsail_volume="${rocm_volume}hcc-hsail/"
export hcc_lc_volume="${rocm_volume}hcc-lc/"

# /lib/x86_64-linux-gnu is debian/ubuntu style not currently used in rocm
# export lib64_install_dir='/lib/x86_64-linux-gnu'
export lib64_install_dir='/lib'

cat rock/rock-deb-dockerfile.template | envsubst '${repo_branch}:${rock_volume}' > rock/Dockerfile
cat roct/roct-thunk-dockerfile.template | envsubst '${rock_name}:${repo_branch}:${build_config_roct}:${roct_cleanup}:${roct_volume}:${lib64_install_dir}' > roct/Dockerfile
cat rocr/rocr-make-dockerfile.template | envsubst '${roct_name}:${repo_branch_rocr}:${build_config}:${rocr_cleanup}:${rocm_volume}:${roct_volume}:${rocr_volume}:${lib64_install_dir}' > rocr/Dockerfile
cat hcc-hsail/hcc-hsail-dockerfile.template | envsubst '${rocr_name}:${repo_branch_hcc_hsail}:${build_config}:${hcc_hsail_cleanup}:${roct_volume}:${rocr_volume}:${hcc_hsail_volume}:${lib64_install_dir}' > hcc-hsail/Dockerfile
cat hcc-lc/hcc-lc-clang-tot-upgrade-dockerfile.template | envsubst '${rocr_name}:${repo_branch_hcc_lc}:${build_config}:${hcc_lc_cleanup}:${rocm_volume}:${roct_volume}:${rocr_volume}:${hcc_lc_volume}' > hcc-lc/Dockerfile

cat docker-compose.yml.template | envsubst '${hcc_lc_name}:${hcc_hsail_name}:${rocr_name}:${roct_name}:${hcc_hsail_volume}:${hcc_lc_volume}:${rocr_volume}:${roct_volume}' > docker-compose.yml
