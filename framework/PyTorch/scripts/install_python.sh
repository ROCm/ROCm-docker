#!/usr/bin/env bash
set -euo pipefail

PYTHON_VERSION="${1:-3.12}"
PY_MAJ_MIN="$(echo "${PYTHON_VERSION}" | awk -F. '{print $1"."$2}')"

if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  DISTRO_ID="${ID}"
else
  echo "Unable to detect distribution (missing /etc/os-release)." >&2
  exit 1
fi

install_apt() {
  apt-get update

  PYTHON_PACKAGES=(
    "python${PY_MAJ_MIN}"
    "python${PY_MAJ_MIN}-venv"
    "python${PY_MAJ_MIN}-dev"
  )
  HAS_NATIVE_PYTHON="true"
  for package in "${PYTHON_PACKAGES[@]}"; do
    if ! apt-cache show "${package}" >/dev/null 2>&1; then
      HAS_NATIVE_PYTHON="false"
      break
    fi
  done

  if [[ "${HAS_NATIVE_PYTHON}" == "true" ]]; then
    apt-get install -y --no-install-recommends \
      "python${PY_MAJ_MIN}" "python${PY_MAJ_MIN}-venv" "python${PY_MAJ_MIN}-dev" python3-pip
  elif [[ "${DISTRO_ID}" == "debian" ]]; then
    echo "python${PY_MAJ_MIN} is not available from this Debian image's apt repositories." >&2
    echo "Use a Debian tag that provides python${PY_MAJ_MIN}, or choose a supported Python version for this base image." >&2
    exit 1
  else
    echo "python${PY_MAJ_MIN} not in default repos, adding deadsnakes PPA..."
    apt-get install -y --no-install-recommends software-properties-common
    add-apt-repository -y ppa:deadsnakes/ppa
    apt-get update
    apt-get install -y --no-install-recommends \
      "python${PY_MAJ_MIN}" "python${PY_MAJ_MIN}-venv" "python${PY_MAJ_MIN}-dev" python3-pip
  fi
  apt-get clean
  rm -rf /var/lib/apt/lists/*
}

install_dnf() {
  dnf install -y --setopt=install_weak_deps=False \
    "python${PY_MAJ_MIN}" "python${PY_MAJ_MIN}-devel" "python${PY_MAJ_MIN}-pip" >/dev/null 2>&1 || \
  dnf install -y --setopt=install_weak_deps=False python3 python3-devel python3-pip
  dnf clean all
}

install_tdnf() {
  tdnf install -y python3 python3-devel python3-pip
  tdnf clean all
}

case "${DISTRO_ID}" in
  ubuntu|debian)
    install_apt
    ;;
  rhel|almalinux|rocky|centos|centos_stream)
    install_dnf
    ;;
  azurelinux)
    install_tdnf
    ;;
  *)
    echo "Unsupported distribution: ${DISTRO_ID}" >&2
    exit 1
    ;;
esac

PY_BIN="$(command -v "python${PY_MAJ_MIN}" || command -v "python${PYTHON_VERSION}" || command -v python3)"
if [[ -z "${PY_BIN}" ]]; then
  echo "Could not locate a python interpreter after installation." >&2
  exit 1
fi

ln -svf "${PY_BIN}" /usr/local/bin/python3 >/dev/null 2>&1 || true
