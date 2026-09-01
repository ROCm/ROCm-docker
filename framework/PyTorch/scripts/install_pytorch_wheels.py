#!/usr/bin/env python3
"""
install_pytorch_wheels.py

Installs PyTorch wheels from a pip index URL.

Usage (from repo root):
    python .github/scripts/install_pytorch_wheels.py --index-url <URL> --amdgpu-family <FAMILY> [OPTIONS]

Examples:
    # Install latest versions
    python .github/scripts/install_pytorch_wheels.py \
        --index-url <BASE_INDEX_URL>/whl \
        --amdgpu-family gfx1250

    # Install specific versions (matching ROCm builds)
    python .github/scripts/install_pytorch_wheels.py \
        --index-url <BASE_INDEX_URL>/whl \
        --amdgpu-family gfx1250 \
        --torch-version "2.10.0+devrocm7.12.0.dev0.849eec43b..." \
        --torchaudio-version "2.11.0a0+devrocm7.12.0.dev0.849eec43b..." \
        --torchvision-version "0.25.0a0+devrocm7.12.0.dev0.849eec43b..." \
        --apex-version "1.10.0+devrocm7.12.0.dev0.849eec43b..."
"""

import argparse
import importlib.util
import os
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


def _load_detect_device_arches():
    """Import scripts/detect_device_arches.py from repo or docker build context."""
    candidates = [
        Path(__file__).resolve().parent / "detect_device_arches.py",
        Path(__file__).resolve().parent.parent / "detect_device_arches.py",
    ]
    for path in candidates:
        if not path.is_file():
            continue
        spec = importlib.util.spec_from_file_location("detect_device_arches", path)
        if spec and spec.loader:
            module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(module)
            return module
    raise ImportError(
        "detect_device_arches.py not found next to install_pytorch_wheels.py "
        "or under scripts/"
    )


_detect = _load_detect_device_arches()
TORCH_DEVICE_ARCHES = _detect.TORCH_DEVICE_ARCHES
ROCM_DEVICE_ARCHES = _detect.ROCM_DEVICE_ARCHES


# Package configuration: (name, always_install)
PACKAGES = {
    "torch": True,
    "torchaudio": True,
    "torchvision": True,
    "apex": True,
    "triton": False,
}
PYTORCH_PKGS = ["torch", "torchaudio", "torchvision", "apex", "triton"]
ROCM_PACKAGE = "rocm"


def is_device_all(value: str | None) -> bool:
    """Return true when the build should use the multi-arch device-all index."""
    return (value or "").lower() in {"all", "device-all", "multi-arch"}


def build_index_url(base_url: str, amdgpu_family: str) -> str:
    """Build the pip index URL, preserving root URLs for multi-arch device-all."""
    normalized_base = base_url.rstrip("/")
    if is_device_all(amdgpu_family) or normalized_base.endswith("whl-multi-arch"):
        return f"{normalized_base}/"
    return f"{normalized_base}/{amdgpu_family}/"


def print_banner(title: str) -> None:
    """Print a formatted banner."""
    print("=" * 50)
    print(title)
    print("=" * 50)


def build_package_spec(name: str, version: str | None) -> str:
    """Build a pip package spec (e.g., 'torch==2.10.0' or 'torch')."""
    return f"{name}=={version}" if version else name


def normalize_dist_name(name: str) -> str:
    """Normalize a distribution name for comparing wheel links."""
    return re.sub(r"[-_.]+", "-", name).lower()


def is_device_package_name(package_name: str) -> bool:
    """Return true for multi-arch device wheel package names."""
    return package_name.startswith(
        ("amd-torch-device-", "amd-torchvision-device-", "rocm-sdk-device-")
    )


def wheel_name_prefix(package_name: str) -> str:
    """Map PEP 503 normalized package names to wheel filename prefixes."""
    return package_name.replace("-", "_").lower()


def package_version_available(index_url: str, package_name: str, version: str) -> bool:
    """Return true when the index lists package_name==version."""
    url = f"{index_url.rstrip('/')}/{package_name}/"
    try:
        with urllib.request.urlopen(url, timeout=30) as resp:
            html = resp.read().decode("utf-8", errors="ignore")
    except Exception:
        return False

    html_decoded = urllib.parse.unquote(html).lower()
    version_norm = version.lower()
    prefixes = {wheel_name_prefix(package_name), package_name.lower()}
    return any(f"{prefix}-{version_norm}" in html_decoded for prefix in prefixes)


def filter_available_packages(index_urls: list[str], packages: list[str]) -> list[str]:
    """Drop device packages that are not published for this index/version."""
    available: list[str] = []
    skipped: list[str] = []

    for spec in packages:
        if "==" not in spec:
            available.append(spec)
            continue

        package_name, version = spec.split("==", 1)
        if not is_device_package_name(package_name):
            available.append(spec)
            continue

        if any(package_version_available(index_url, package_name, version) for index_url in index_urls):
            available.append(spec)
        else:
            skipped.append(spec)

    if skipped:
        print(f"Skipping unavailable device packages ({len(skipped)}):")
        for spec in skipped:
            print(f"  - {spec}")

    return available


def device_package_specs(
    versions: dict[str, str | None],
    device_targets: str,
    index_url: str,
) -> list[str]:
    """Return device package specs for the multi-arch device-all index."""
    if not is_device_all(device_targets):
        return []

    return _detect.build_device_package_specs(
        index_url,
        torch_version=versions.get("torch"),
        torchvision_version=versions.get("torchvision"),
        rocm_version=versions.get(ROCM_PACKAGE),
        spec_builder=build_package_spec,
    )



def get_latest_package_version_for_rocm(
    index_url: str, package_name: str, rocm_version: str, required: bool = True
) -> str | None:
    """Return latest package version containing rocm_version by parsing the index HTML."""
    rocm_tag = f"rocm{rocm_version}"
    url = f"{index_url.rstrip('/')}/{package_name}/"
    try:
        with urllib.request.urlopen(url, timeout=30) as resp:
            html = resp.read().decode("utf-8", errors="ignore")
    except Exception as e:
        print(f"Error: failed to fetch index for {package_name}: {e}", file=sys.stderr)
        sys.exit(1)

    pattern = re.compile(
        re.escape(package_name) + r"-(.+?)\.whl",
        re.IGNORECASE,
    )
    all_suffixes = [m.group(1).strip() for m in pattern.finditer(html)]
    matching = []
    for s in all_suffixes:
        ver = s.split("-")[0]
        if rocm_tag in ver:
            matching.append(urllib.parse.unquote(ver))
    if not matching:
        if required:
            print(
                f"Error: no wheel found for {package_name} with ROCm {rocm_version}",
                file=sys.stderr,
            )
            sys.exit(1)
        return None

    def _key(v: str) -> tuple[int, ...]:
        try:
            part = v.split("+")[0]
            return tuple(int(x) for x in re.split(r"[.\-]", part) if x.isdigit())
        except (ValueError, AttributeError):
            return (0,)

    return max(matching, key=_key)


def run_pip_install(
    index_url: str,
    extra_index_urls: list[str],
    packages: list[str],
    break_system_packages: bool = True,
) -> None:
    """Run pip install with the given packages."""
    cmd = [
        sys.executable,
        "-m",
        "pip",
        "install",
        "--no-cache-dir",
        "--index-url",
        index_url,
    ]
    for extra_index_url in extra_index_urls:
        cmd.extend(["--extra-index-url", extra_index_url])

    if break_system_packages:
        cmd.append("--break-system-packages")

    cmd.extend(packages)

    print(f"Running: {' '.join(cmd)}")
    result = subprocess.run(cmd, check=False)

    if result.returncode != 0:
        print(f"Error: pip install failed with return code {result.returncode}")
        sys.exit(result.returncode)


def check_package(name: str) -> tuple[bool, str | None]:
    """Check if a package is installed and return (installed, version)."""
    try:
        module = __import__(name)
        return True, getattr(module, "__version__", "unknown")
    except ImportError:
        return False, None


def verify_installation(extra_pkgs: list[str] | None = None) -> bool:
    """Verify PyTorch installation and print version info."""
    print_banner("Verifying Installation")

    try:
        import torch as _torch

        version = getattr(_torch, "__version__", "unknown")
    except ImportError as e:
        print(
            f"Error: torch import failed ({e!r}). If wheels are installed, run rocm-sdk init first."
        )
        return False

    print(f"torch: {version}")

    hip_version = _torch.version.hip
    print(f"ROCm/HIP: {hip_version or 'not available'}")
    print(f"Built with ROCm: {hip_version is not None}")

    for name in extra_pkgs or ["torchaudio", "torchvision", "apex", "triton", "rocm"]:
        installed, version = check_package(name)
        status = version if installed else "not installed"
        print(f"{name}: {status}")

    return True


def list_installed_packages() -> None:
    """List installed torch-related packages."""
    print("\nInstalled PyTorch packages:")
    result = subprocess.run(
        [sys.executable, "-m", "pip", "list"],
        capture_output=True,
        text=True,
        check=False,
    )

    if result.returncode == 0:
        keywords = ["torch", "apex", "triton", "rocm"]
        for line in result.stdout.splitlines():
            if any(kw in line.lower() for kw in keywords):
                print(f"  {line}")


def _installed_device_distributions(prefix: str) -> list[str]:
    """Return installed distribution names that start with ``prefix``."""
    import importlib.metadata as md

    names = []
    for dist in md.distributions():
        name = (dist.metadata.get("Name") or "").lower()
        if name.startswith(f"{prefix}-"):
            names.append(name)
    return sorted(set(names))


def _torch_package_dir() -> str | None:
    """Resolve the installed torch package directory via the active interpreter."""
    venv = os.environ.get("VIRTUAL_ENV")
    if venv and not sys.executable.startswith(venv.rstrip("/")):
        print(
            f"Warning: script is running outside the venv ({sys.executable}); "
            "device-code verification uses this interpreter's site-packages.",
            file=sys.stderr,
        )

    result = subprocess.run(
        [sys.executable, "-m", "pip", "show", "torch"],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode == 0:
        location = None
        for line in result.stdout.splitlines():
            if line.startswith("Location:"):
                location = line.split(":", 1)[1].strip()
                break
        if location:
            candidate = os.path.join(location, "torch")
            if os.path.isdir(candidate):
                return candidate

    try:
        import importlib.util

        spec = importlib.util.find_spec("torch")
        if spec and spec.origin:
            return os.path.dirname(spec.origin)
    except Exception:
        pass
    return None


def verify_device_code(device_targets: str) -> bool:
    """Fail-closed check that GPU device code is actually present after install.

    The host ``torch`` wheel ships ``.hip_fatbin`` as NOBITS (no embedded code);
    the device code lives in per-arch ``amd-torch-device-*`` packages that overlay
    ``torch/.kpack/torch_<arch>.kpack``. If those are missing, the image imports
    fine but every kernel launch fails at runtime with hipErrorInvalidImage.

    This gate makes such a build fail (non-zero exit) BEFORE the image is pushed.
    """
    if not is_device_all(device_targets):
        return True

    print_banner("Verifying GPU device code (kpack)")

    device_dists = _installed_device_distributions("amd-torch-device")
    if not device_dists:
        print(
            "Error: device-all build but no 'amd-torch-device-*' packages are "
            "installed. The image would have no GPU device code "
            "(hipErrorInvalidImage at runtime). Refusing to continue.",
            file=sys.stderr,
        )
        return False

    try:
        torch_dir = _torch_package_dir()
    except Exception as exc:  # pragma: no cover - defensive
        print(f"Error: could not locate the torch package: {exc}", file=sys.stderr)
        return False

    if not torch_dir:
        print("Error: could not locate the torch package directory.", file=sys.stderr)
        return False

    kpack_dir = os.path.join(torch_dir, ".kpack")
    kpacks = (
        [f for f in os.listdir(kpack_dir) if f.endswith(".kpack")]
        if os.path.isdir(kpack_dir)
        else []
    )

    print(f"Installed amd-torch-device packages: {len(device_dists)}")
    print(f"kpack files in {kpack_dir}: {len(kpacks)}")

    # Note: a 1:1 package-to-kpack count is not required. Some device packages
    # are umbrella/family aggregates (e.g. gfx11, gfx12-0) that do not emit their
    # own per-arch .kpack. The packaging defect we guard against is GPU device
    # code being entirely absent, so we require at least one materialized kpack.
    if not kpacks:
        print(
            f"Error: no '.kpack' device-code files found under {kpack_dir} despite "
            f"{len(device_dists)} amd-torch-device package(s) installed. The GPU "
            "device code is missing (hipErrorInvalidImage at runtime). "
            "Refusing to continue.",
            file=sys.stderr,
        )
        return False

    print(f"GPU device code present ({len(kpacks)} kpack file(s)).")
    return True


def main() -> int:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Install PyTorch wheels from a pip index URL",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )

    parser.add_argument(
        "--index-url", required=True, help="Base URL for PyTorch wheels index"
    )
    parser.add_argument(
        "--extra-index-url",
        action="append",
        default=[],
        help="Additional pip index URL(s), e.g. released ROCm SDK packages.",
    )
    parser.add_argument(
        "--amdgpu-family", required=True, help="AMD GPU family (e.g., gfx1250)"
    )
    parser.add_argument(
        "--device-targets",
        default=None,
        help="Device package target set. Use 'device-all' to install every device package from the multi-arch index.",
    )
    parser.add_argument(
        "--rocm-version",
        help="Optional. ROCm version (e.g. 7.12.0a20260126). When set without --torch-version: discovers and installs latest torch/torchaudio/torchvision/triton built for this ROCm. ",
    )
    parser.add_argument(
        "--torch-version", help="Specific torch version (default: latest)"
    )
    parser.add_argument(
        "--torchaudio-version", help="Specific torchaudio version (default: latest)"
    )
    parser.add_argument(
        "--torchvision-version", help="Specific torchvision version (default: latest)"
    )
    parser.add_argument(
        "--apex-version", help="Specific apex version (default: latest)"
    )
    parser.add_argument(
        "--triton-version",
        help="Specific triton version (default: from torch dependency)",
    )
    parser.add_argument(
        "--no-break-system-packages",
        action="store_true",
        help="Don't use --break-system-packages",
    )
    parser.add_argument(
        "--skip-verify", action="store_true", help="Skip verification step"
    )
    parser.add_argument(
        "--skip-apex",
        action="store_true",
        help="Do not install apex (avoids its PyPI-only deps like cxxfilt)",
    )
    parser.add_argument(
        "--pin-explicit-versions",
        action="store_true",
        help=(
            "Honor explicitly requested wheel versions without falling back to "
            "latest from a different ROCm build. Unspecified companion packages "
            "(torchaudio, torchvision, etc.) are still resolved from the pinned "
            "ROCm index."
        ),
    )

    args = parser.parse_args()

    packages_config = dict(PACKAGES)
    pytorch_pkgs = list(PYTORCH_PKGS)
    verify_pkgs = ["torchaudio", "torchvision", "apex", "triton", ROCM_PACKAGE]
    if args.skip_apex:
        packages_config.pop("apex", None)
        pytorch_pkgs = [p for p in pytorch_pkgs if p != "apex"]
        verify_pkgs = [p for p in verify_pkgs if p != "apex"]

    device_targets = args.device_targets or args.amdgpu_family

    index_url = build_index_url(args.index_url, args.amdgpu_family)
    extra_index_urls = [
        build_index_url(url, args.amdgpu_family) for url in args.extra_index_url
    ]
    index_urls = [index_url, *extra_index_urls]

    rocm = args.rocm_version
    arg_attrs = [
        "torch_version",
        "torchaudio_version",
        "torchvision_version",
        "apex_version",
        "triton_version",
    ]
    requested_versions = {p: getattr(args, a) for p, a in zip(PYTORCH_PKGS, arg_attrs)}

    if rocm:
        versions = {}
        for package in pytorch_pkgs:
            requested_version = requested_versions[package]
            if requested_version:
                versions[package] = requested_version
            elif packages_config.get(package):
                require_rocm_match = (not args.pin_explicit_versions) or package == "torch"
                discovered = get_latest_package_version_for_rocm(
                    index_url,
                    package,
                    rocm,
                    required=require_rocm_match,
                )
                if args.pin_explicit_versions and discovered is None:
                    print(
                        f"Warning: no ROCm {rocm} wheel found for {package}; "
                        "skipping unpinned install in pin-explicit mode.",
                        file=sys.stderr,
                    )
                versions[package] = discovered
            else:
                versions[package] = None
    else:
        versions = requested_versions
    versions[ROCM_PACKAGE] = rocm if rocm else None

    print_banner("PyTorch Wheels Installation")
    print(f"Index URL:      {index_url}")
    for extra_index_url in extra_index_urls:
        print(f"Extra index:    {extra_index_url}")
    print(f"AMDGPU Family:  {args.amdgpu_family}")
    print(f"Python:         {sys.version_info.major}.{sys.version_info.minor}")
    for name, version in versions.items():
        print(f"{name:14}: {version or 'latest'}")
    print("=" * 50)

    packages = []
    for name, always_install in packages_config.items():
        version = versions.get(name)
        if version:
            packages.append(build_package_spec(name, version))
        elif always_install and not args.pin_explicit_versions:
            packages.append(build_package_spec(name, None))
    packages.append(build_package_spec(ROCM_PACKAGE, versions[ROCM_PACKAGE]))
    packages.extend(device_package_specs(versions, device_targets, index_url))
    packages = filter_available_packages(index_urls, packages)

    print(f"Installing: {', '.join(packages)}")
    run_pip_install(index_url, extra_index_urls, packages, not args.no_break_system_packages)

    if not args.skip_verify and not verify_installation(verify_pkgs):
        return 1

    # Fail-closed device-code gate: never publish a device-all image that is
    # missing GPU device code. This runs regardless of --skip-verify because it
    # guards against a packaging defect, not a runtime smoke test.
    if not verify_device_code(device_targets):
        return 1

    list_installed_packages()
    print_banner("Installation complete")
    return 0


if __name__ == "__main__":
    sys.exit(main())
