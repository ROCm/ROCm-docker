#!/usr/bin/env bash
# #################################################
# Copyright (c) 2016 Advanced Micro Devices, Inc.
# #################################################

# Set reasonable defaults for dockerfile builds
# Default: --master, --release

# #################################################
# Initialization of command line parameters
# #################################################
# Build dockerfiles from more stable master branches; exclusive with --develop
build_master=true

# Build dockerfiles from newer develop branches; exclusive with --master
build_develop=

# Build release binaries; this cleans up and deletes the build to minimize docker image; exclusive with --debug
build_release=true

# Build debug binaries; this leaves build tree intact for greater debugging; exclusive with --release
build_debug=

# #################################################
# helper functions
# #################################################
function display_help()
{
  echo "Building ROC docker images from templates"
  echo "Usage: ./rocm-setup [--master | --develop] [--release | --debug]"
  echo "Default flags: --master --release"
  echo ""
  echo "--master) Build dockerfiles from stable master branches; exclusive with --develop"
  echo "--develop) Build dockerfiles from integration branches; exclusive with --master"
  echo "--release) Build release containers; minimizes size of docker images; exclusive with --debug"
  echo "--debug) Build debug containers; symbols generated and build tree intact for debugging; exclusive with --release"
}

# #################################################
# Start of main
# #################################################
while :; do
  case $1 in
    --master)
      build_master=true
      build_develop=
      ;;
    --develop)
      build_master=
      build_develop=true
      ;;
    --release)
      build_release=true
      build_debug=
      ;;
    --debug)
      build_release=
      build_debug=true
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
