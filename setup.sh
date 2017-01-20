#!/usr/bin/env bash
# #################################################
# Copyright (c) 2016 Advanced Micro Devices, Inc.
# #################################################
# Author: Kent Knox

# #################################################
# Pre-requisites check
# #################################################
if (( ${BASH_VERSION%%.*} < 4 )); then
  printf "This script uses associative arrays, requiring Bash 4.x minimum\n"
  exit 2
fi

# check if curl is installed
type curl > /dev/null
if [[ $? -ne 0 ]]; then
  printf "This script uses curl to download components; try installing with package manager\n";
  exit 2
fi

# check if getopt command is installed
type getopt > /dev/null
if [[ $? -ne 0 ]]; then
  printf "This script uses getopt to parse arguments; try installing the util-linux package\n";
  exit 2
fi

# lsb-release file describes the system
if [[ ! -e "/etc/lsb-release" ]]; then
  printf "This script depends on the /etc/lsb-release file\n"
  exit 2
fi
source /etc/lsb-release

if [[ ${DISTRIB_CODENAME} != trusty ]] && [[ ${DISTRIB_CODENAME} != xenial ]]; then
  printf "This script only validated with Ubuntu trusty [14.04] or xenial [16.04]\n"
  exit 2
fi

# #################################################
# helper functions
# #################################################
function display_help()
{
  printf "Build ROC docker images from templates\n\n"
  printf "    [-h|--help] prints this help message\n"
  printf "    [--ubuntu xx.yy] Ubuntu version for to inherit base image (16.04 / 14.04)\n"
  printf "    [--tag] String specifying branch or tag in git repository (requires --build)\n"
  printf "    [--branch] Same as tag; alias\n"
#  printf "    [--all] Build as many components as you can\n"
#  printf "    [--roct] Build roct component\n"
#  printf "    [--rocr] Build rocr component\n"
#  printf "    [--hcc-lc] Build hcc-lc component\n"
#  printf "    [--hcc-hsail] Build hcc-hsail component\n"
  printf "    [--debug] Build debug containers; symbols generated and build tree intact for debugging; (requires --build, exclusive with --release)\n"
  printf "    [--install-docker-compose] install the docker-compose tool\n"
}

# #################################################
# global variables & defaults
# #################################################
# Array describing what rocm components to build docker images for
rocm_components=()

# If building components from source, script defaults to master branch if no tag name is explicitely specified
export tag='master'
export ubuntu_version='16.04'
export target_distrib_codename=xenial

export build_config='Release'
build_release=true
install_compose=false

# Bash associative arrays
# declare -A thunk_branch_names=( ['master']=master ['develop']=dev ['roc-1.0']=roc-1.0.x ['roc-1.1']=roc-1.1.x ['roc-1.2']=roc-1.2.x ['roc-1.3']=roc-1.3.x ['roc-1.4']=roc-1.4.x )
# declare -A runtime_branch_names=( ['master']=master ['develop']= ['roc-1.0']= ['roc-1.1']= ['roc-1.2']=roc-1.2.x ['roc-1.3']=roc-1.3.x ['roc-1.4']=roc-1.4.x )
# declare -A hcc_lc_branch_names=( ['master']= ['develop']=develop ['roc-1.0']=roc-1.0.x ['roc-1.1']=roc-1.1.x ['roc-1.2']=roc-1.2.x ['roc-1.3']=roc-1.3.x ['roc-1.4']=roc-1.4.x ['hcc-4.0']=clang_tot_upgrade )
# declare -A hcc_hsail_branch_names=( ['master']=master ['develop']= ['roc-1.0']= ['roc-1.1']= ['roc-1.2']= ['roc-1.3']= ['roc-1.4']= )

declare -A thunk_dockerfiles=( ['src-template']=roct-thunk-src-dockerfile.template ['deb-template']=roct-thunk-deb-dockerfile.template ['src']=roct-thunk-src-dockerfile ['deb']=roct-thunk-deb-dockerfile )
declare -A runtime_dockerfiles=( ['src-template']=rocr-src-dockerfile.template ['deb-template']=rocr-deb-dockerfile.template ['src']=rocr-src-dockerfile ['deb']=rocr-deb-dockerfile )
declare -A hcc_lc_dockerfiles=( ['src-template']=hcc-lc-clang-tot-upgrade-dockerfile.template ['deb-template']=hcc-lc-deb-dockerfile.template ['src']=hcc-lc-clang-tot-upgrade-dockerfile ['deb']=hcc-lc-deb-dockerfile)
declare -A hcc_hsail_dockerfiles=( ['src-template']=hcc-hsail-dockerfile.template ['deb-template']=hcc-hsail-deb-dockerfile.template ['src']=hcc-hsail-dockerfile ['deb']=hcc-hsail-deb-dockerfile )

# #################################################
# Parameter parsing
# #################################################

# check if we have a modern version of getopt that can handle whitespace and long parameters
getopt -T
if [[ $? -eq 4 ]]; then
#  GETOPT_PARSE=$(getopt --name "${0}" --longoptions help,ubuntu:,tag:,branch:,all,roct,rocr,hcc-lc,hcc-hsail,release,debug,install-docker-compose --options h -- "$@")
  GETOPT_PARSE=$(getopt --name "${0}" --longoptions help,ubuntu:,tag:,branch:,release,debug,install-docker-compose --options h -- "$@")
else
  printf "Legacy getopt not handled"
  exit 1
fi

if [[ $? -ne 0 ]]; then
  printf "getopt invocation failed; could not parse the command line\n";
  exit 1
fi

eval set -- "${GETOPT_PARSE}"

while true; do
  case "${1}" in
    -h|--help)
      display_help
      exit 0
      ;;
    --ubuntu)
      ubuntu_version=${2}
      shift 2;;
    --tag|--branch)
      tag=${2}
      shift 2;;
    # --all)
    #   rocm_components=('roct' 'rocr' 'hcc-lc' 'hcc-hsail')
    #   shift ;;
    # --roct)
    #   rocm_components+=('roct')
    #   shift ;;
    # --rocr)
    #   rocm_components+=('rocr')
    #   shift ;;
    # --hcc-lc)
    #   rocm_components+=('hcc-lc')
    #   shift ;;
    # --hcc-hsail)
    #   rocm_components+=('hcc-hsail')
    #   shift ;;
    --debug)
      build_config='Debug'
      build_release=false
      shift ;;
    --install-docker-compose)
      install_compose=true
      shift ;;
    --) shift ; break ;;
    *)  printf "getopt parsing error";
        exit 2
        ;;
  esac
done

# #################################################
# docker-compose
# Help users install the latest docker-compose on their machine
# #################################################
if [[ "${install_compose}" == true ]]; then
  sudo curl -L $(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep browser_download_url.*-Linux | cut -d\" -f 4) -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose

  sudo curl -L https://raw.githubusercontent.com/docker/compose/$(docker-compose version --short)/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose
fi

# #################################################
# Start of main
# #################################################

if [[ "${ubuntu_version}" == 14.04  ]]; then
  target_distrib_codename=trusty
fi

printf "== Branch/tag to build: %s\n" ${tag}
if [[ "${build_release}" == true ]]; then
  printf "==== Release builds \n"
else
  printf "==== Debug builds \n"
fi

# Keep only the unique rocm_components
# printf "rocm_components count: " ${#rocm_components[@]}
# rocm_components=($(printf "%s\n" "${rocm_components[@]}" | uniq -u))
#
# if [ ${#rocm_components[@]} -ne 0 ]; then
#   printf "== Rocm images to build: "
#
#   for key in ${!rocm_components[@]}; do
#     if [ -n "${rocm_components[$key]}" ]; then
#       printf "${rocm_components[$key]} "
#     else
#       printf "NULL\n"
#     fi
#   done
#   printf "\n"
# fi

# export rock_image_name=
organization_prefix="rocm/"

roct_image_name="${organization_prefix}/roct"
rocr_image_name="${organization_prefix}/rocr"
hcc_lc_image_name="${organization_prefix}/hcc-lc"
hcc_hsail_image_name="${organization_prefix}/hcc-hsail"

export roct_image_name_deb="${roct_image_name}-ubuntu-${ubuntu_version}:latest"
export rocr_image_name_deb="${rocr_image_name}-ubuntu-${ubuntu_version}:latest"
export hcc_lc_image_name_deb="${hcc_lc_image_name}-ubuntu-${ubuntu_version}:latest"
export hcc_hsail_image_name_deb="${hcc_hsail_image_name}-ubuntu-${ubuntu_version}:latest"

export roct_image_name_src="${roct_image_name}-src-${build_config,}:${tag}"
export rocr_image_name_src="${rocr_image_name}-src-${build_config,}:${tag}"
export hcc_lc_image_name_src="${hcc_lc_image_name}-src-${build_config,}:${tag}"
export hcc_hsail_image_name_src="${hcc_hsail_image_name}-src-${build_config,}:${tag}"

export roct_cleanup=
export rocr_cleanup=
export hcc_hsail_cleanup=
export hcc_lc_cleanup=

if [[ "${build_release}" == true ]]; then
  # Custom commands to clean up build directories for each component
  # This is to keep release images as small as possible
  roct_cleanup='cd ~ && rm -rf ${HSATHK_BUILD_PATH}'
  rocr_cleanup='cd ~ && rm -rf ${ROCR_BUILD_PATH}'
  hcc_hsail_cleanup='cd ~ && rm -rf ${HCC_BUILD_PATH}'
  hcc_lc_cleanup='cd ~ && rm -rf ${HCC_BUILD_PATH}'
fi

export rocm_volume='/opt/rocm/'
export roct_volume="${rocm_volume}/libhsakmt/"
export rocr_volume="${rocm_volume}/hsa/"
export hcc_hsail_volume="${rocm_volume}/hcc-hsail/"
export hcc_lc_volume="${rocm_volume}/hcc-lc/"

# /lib/x86_64-linux-gnu is debian/ubuntu style not currently used in rocm
# export lib64_install_dir='/lib/x86_64-linux-gnu'
export lib64_install_dir='/lib'

# trim duplicate path seperators
roct_image_name_deb=$(echo "${roct_image_name_deb}" | tr -s '/' )
rocr_image_name_deb=$(echo "${rocr_image_name_deb}" | tr -s '/' )
hcc_lc_image_name_deb=$(echo "${hcc_lc_image_name_deb}" | tr -s '/' )
hcc_hsail_image_name_deb=$(echo "${hcc_hsail_image_name_deb}" | tr -s '/' )

roct_image_name_src=$(echo "${roct_image_name_src}" | tr -s '/' )
rocr_image_name_src=$(echo "${rocr_image_name_src}" | tr -s '/' )
hcc_lc_image_name_src=$(echo "${hcc_lc_image_name_src}" | tr -s '/' )
hcc_hsail_image_name_src=$(echo "${hcc_hsail_image_name_src}" | tr -s '/' )

roct_volume=$(echo "${roct_volume}" | tr -s '/' )
rocr_volume=$(echo "${rocr_volume}" | tr -s '/' )
hcc_lc_volume=$(echo "${hcc_lc_volume}" | tr -s '/' )
hcc_hsail_volume=$(echo "${hcc_hsail_volume}" | tr -s '/' )

# Generate the .env file used by the docker-compose tool
printf "HCC_VERSION=4.0\n\n" > .env
printf "roct_image_name_deb=${roct_image_name_deb}\n" >> .env
printf "rocr_image_name_deb=${rocr_image_name_deb}\n" >> .env
printf "hcc_lc_image_name_deb=${hcc_lc_image_name_deb}\n" >> .env
printf "hcc_hsail_image_name_deb=${hcc_hsail_image_name_deb}\n" >> .env
printf "roct_image_name_src=${roct_image_name_src}\n">> .env
printf "rocr_image_name_src=${rocr_image_name_src}\n" >> .env
printf "hcc_lc_image_name_src=${hcc_lc_image_name_src}\n" >> .env
printf "hcc_hsail_image_name_src=${hcc_hsail_image_name_src}\n" >> .env

printf "\n" >> .env
printf "roct_volume=${roct_volume}\n" >> .env
printf "rocr_volume=${rocr_volume}\n" >> .env
printf "hcc_lc_volume=${hcc_lc_volume}\n" >> .env

printf "\n" >> .env
printf "roct_deb_dockerfile=${thunk_dockerfiles[deb]}\n" >> .env
printf "roct_src_dockerfile=${thunk_dockerfiles[src]}\n" >> .env
printf "rocr_deb_dockerfile=${runtime_dockerfiles[deb]}\n" >> .env
printf "rocr_src_dockerfile=${runtime_dockerfiles[src]}\n" >> .env
printf "hcc_lc_deb_dockerfile=${hcc_lc_dockerfiles[deb]}\n" >> .env
printf "hcc_lc_src_dockerfile=${hcc_lc_dockerfiles[src]}\n" >> .env

# cat rock/rock-deb-dockerfile.template | envsubst '${repo_branch}:${rock_volume}' > rock/Dockerfile
cat roct/${thunk_dockerfiles[deb-template]} | envsubst '${ubuntu_version}:${target_distrib_codename}' > roct/${thunk_dockerfiles[deb]}
cat roct/${thunk_dockerfiles[src-template]} | envsubst '${ubuntu_version}:${tag}:${build_config}:${roct_cleanup}:${roct_volume}:${lib64_install_dir}' > roct/${thunk_dockerfiles[src]}
cat rocr/${runtime_dockerfiles[deb-template]} | envsubst '${roct_image_name_deb}' > rocr/${runtime_dockerfiles[deb]}
cat rocr/${runtime_dockerfiles[src-template]} | envsubst '${roct_image_name_src}:${tag}:${build_config}:${rocr_cleanup}:${rocm_volume}:${roct_volume}:${rocr_volume}:${lib64_install_dir}' > rocr/${runtime_dockerfiles[src]}
cat hcc-lc/${hcc_lc_dockerfiles[deb-template]} | envsubst '${rocr_image_name_deb}' > hcc-lc/${hcc_lc_dockerfiles[deb]}
cat hcc-lc/${hcc_lc_dockerfiles[src-template]} | envsubst '${rocr_image_name_src}:${tag}:${build_config}:${hcc_lc_cleanup}:${rocm_volume}:${hcc_lc_volume}' > hcc-lc/${hcc_lc_dockerfiles[src]}
