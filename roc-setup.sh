#!/usr/bin/env bash

# Set reasonable defaults for dockerfile builds
# Default: --master, --release

# #################################################
# Initialization of command line parameters
# #################################################
# Build dockerfiles from more stable master branches; exclusive with --develop
build_master=1

# Build dockerfiles from newer develop branches; exclusive with --master
build_develop=

# Build release binaries; this cleans up and deletes the build to minimize docker image; exclusive with --debug
build_release=1

# Build debug binaries; this leaves build tree intact for greater debugging; exclusive with --release
build_debug=

# #################################################
# helper functions
# #################################################
function display_help()
{
  echo "Building ROC docker images from templates"
  echo "Usage: ./roc-setup [--master | --develop] [--release | --debug]"
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

# hcc-hsail does not have a develop branch
export repo_branch_hcc_hsail="master"

# hcc-isa conforms to a non git-flow naming scheme, 'master' changes the most
export repo_branch_hcc_isa=

export repo_branch=
if [ -n "${build_master}" ]; then
  repo_branch="master"
  repo_branch_hcc_isa="testing"
else
  repo_branch="dev"
  repo_branch_hcc_isa="master"
fi

export build_config=
export build_config_roct=
export roct_cleanup=
export rocr_cleanup=
export hcc_hsail_cleanup=
export hcc_isa_cleanup=
export rock_name=
export roct_name=
export rocr_name=
export hcc_hsail_name=
export hcc_isa_name=

rocm_prefix="rocm/"
if [ -n "${build_release}" ]; then
  build_config='Release'

  rock_name="${rocm_prefix}rock-${repo_branch}"
  roct_name="${rocm_prefix}roct-${repo_branch}"
  rocr_name="${rocm_prefix}rocr-${repo_branch}"
  hcc_hsail_name="${rocm_prefix}hcc-hsail-${repo_branch_hcc_hsail}"
  hcc_isa_name="${rocm_prefix}hcc-isa-${repo_branch_hcc_isa}"

  # Custom commands to clean up build directories for each component
  # This is to keep release images as small as possible
  build_config_roct='REL=1'
  roct_cleanup='cd ~ && rm -rf ${HSATHK_BUILD_PATH} &&'
  rocr_cleanup='cd ~ && rm -rf ${ROCR_BUILD_PATH} &&'
  hcc_hsail_cleanup='cd ~ && rm -rf ${HCC_BUILD_PATH} &&'
  hcc_isa_cleanup='cd ~ && rm -rf ${HCC_BUILD_PATH} &&'
else
  build_config='Debug'

  # For debug builds, name the images as 'debug'
  # The comma operator in ${build_config} makes the first letter lower case
  rock_name="${rocm_prefix}rock-${repo_branch}"
  roct_name="${rocm_prefix}roct-${repo_branch}-${build_config,}"
  rocr_name="${rocm_prefix}rocr-${repo_branch}-${build_config,}"
  hcc_hsail_name="${rocm_prefix}hcc-hsail-${repo_branch_hcc_hsail}-${build_config,}"
  hcc_isa_name="${rocm_prefix}hcc-isa-${repo_branch_hcc_isa}-${build_config,}"
fi

export roct_volume='/opt/roct/'
export rocr_volume='/opt/hsa/'
export hcc_volume='/opt/hcc/'

# Uncomment below to print dockerfiles with template substitutions; debugging
cat rock/rock-deb-dockerfile.template | envsubst '${repo_branch}' > rock/Dockerfile
cat roct/roct-thunk-dockerfile.template | envsubst '${rock_name}:${repo_branch}:${build_config_roct}:${roct_cleanup}:${roct_volume}' > roct/Dockerfile
cat rocr/rocr-make-dockerfile.template | envsubst '${roct_name}:${repo_branch}:${build_config}:${rocr_cleanup}:${rocr_volume}' > rocr/Dockerfile
cat hcc-hsail/hcc-hsail-dockerfile.template | envsubst '${rocr_name}:${repo_branch_hcc_hsail}:${build_config}:${hcc_hsail_cleanup}:${hcc_volume}' > hcc-hsail/Dockerfile
cat hcc-isa/hcc-isa-dockerfile.template | envsubst '${rocr_name}:${repo_branch_hcc_isa}:${build_config}:${hcc_isa_cleanup}:${hcc_volume}' > hcc-isa/Dockerfile

cat docker-compose.yml.template | envsubst '${hcc_isa_name}:${hcc_hsail_name}:${rocr_name}:${roct_name}:${hcc_volume}:${rocr_volume}:${roct_volume}' > docker-compose.yml
