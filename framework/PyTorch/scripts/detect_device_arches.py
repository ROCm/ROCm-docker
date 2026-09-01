#!/usr/bin/env python3
"""
detect_device_arches.py

Discover which per-arch device packages are published on a PyTorch wheel index.

Companion to scripts/detect-rocm-version.sh (ROCm + core package resolution).
This script answers: for a given index + wheel versions, which
``amd-torch-device-*``, ``amd-torchvision-device-*``, and ``rocm-sdk-device-*``
architectures actually exist?

Usage (standalone):
    python scripts/detect_device_arches.py \\
        --index-url https://rocm.prereleases.amd.com/whl-multi-arch/ \\
        --torch-version 2.12.0+rocm7.14.0rc1 \\
        --torchvision-version 0.27.0+rocm7.14.0rc1 \\
        --rocm-version 7.14.0rc1

Environment (optional, mirror detect-rocm-version.sh style):
    INDEX_URL, TORCH_VERSION, TORCHVISION_VERSION, ROCM_VERSION
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Callable

ROCM_DEVICE_ARCHES = [
    "gfx1010",
    "gfx1011",
    "gfx1012",
    "gfx1030",
    "gfx1031",
    "gfx1032",
    "gfx1033",
    "gfx1034",
    "gfx1035",
    "gfx1036",
    "gfx1100",
    "gfx1101",
    "gfx1102",
    "gfx1103",
    "gfx1150",
    "gfx1151",
    "gfx1152",
    "gfx1153",
    "gfx1200",
    "gfx1201",
    "gfx900",
    "gfx906",
    "gfx908",
    "gfx90a",
    "gfx942",
    "gfx950",
]
TORCH_DEVICE_FAMILY_BUNDLES = ["gfx11", "gfx110x", "gfx115x", "gfx12-0"]
TORCH_DEVICE_ARCHES = ROCM_DEVICE_ARCHES + TORCH_DEVICE_FAMILY_BUNDLES

DEFAULT_PROBE_WORKERS = 8


def log(message: str) -> None:
    print(f"[detect-device-arches] {message}", file=sys.stderr)


def index_has_package_version(
    index_url: str, package_name: str, version: str | None
) -> bool:
    """Return True when the index publishes ``package_name`` (matching ``version``).

    Only a definitive absent response (HTTP 403/404) is treated as not-available.
    Inconclusive failures assume available so callers fail loudly at install time
    instead of silently skipping device code during a transient outage.
    """
    url = f"{index_url.rstrip('/')}/{package_name}/"
    try:
        with urllib.request.urlopen(url, timeout=30) as resp:
            html = resp.read().decode("utf-8", errors="ignore")
    except urllib.error.HTTPError as exc:
        if exc.code in (403, 404):
            return False
        log(
            f"HTTP {exc.code} checking {package_name}; "
            "assuming available (install will fail loudly if it is not)."
        )
        return True
    except Exception as exc:
        log(
            f"could not check {package_name} ({exc}); "
            "assuming available (install will fail loudly if it is not)."
        )
        return True

    if ".whl" not in html:
        return False
    if not version:
        return True
    return version in html or version.replace("+", "%2B") in html


def fetch_index_html(index_url: str) -> str | None:
    """Fetch and decode an index page, returning None on inconclusive failures."""
    try:
        with urllib.request.urlopen(index_url.rstrip("/") + "/", timeout=30) as resp:
            return resp.read().decode("utf-8", errors="ignore")
    except urllib.error.HTTPError as exc:
        log(f"HTTP {exc.code} fetching {index_url}; using fallback arch list.")
        return None
    except Exception as exc:
        log(f"could not fetch {index_url} ({exc}); using fallback arch list.")
        return None


def discover_arch_candidates_from_index(
    index_url: str, package_prefix: str, fallback_arches: list[str]
) -> list[str]:
    """Discover device arch suffixes by scraping the root simple index.

    The fallback list keeps behavior stable if the index cannot be read. Scraped
    arches are appended after the fallback order, so new packages such as
    ``gfx1250`` are picked up automatically without reordering existing installs.
    """
    html = fetch_index_html(index_url)
    if not html:
        return list(fallback_arches)

    normalized_html = urllib.parse.unquote(html).lower().replace("_", "-")
    prefix = package_prefix.lower().replace("_", "-") + "-"
    directory_pattern = re.compile(
        re.escape(prefix) + r"([a-z0-9][a-z0-9-]*?)(?=(?:/|\"|<|\s))"
    )
    wheel_pattern = re.compile(
        re.escape(prefix) + r"([a-z0-9][a-z0-9-]*?)-\d[^/\"<\s]*\.whl"
    )

    discovered = sorted(
        set(directory_pattern.findall(normalized_html))
        | set(wheel_pattern.findall(normalized_html))
    )
    if not discovered:
        return list(fallback_arches)

    candidates = list(fallback_arches)
    for arch in discovered:
        if arch not in candidates:
            candidates.append(arch)
    return candidates


def discover_device_arches(
    index_url: str,
    package_prefix: str,
    candidate_arches: list[str],
    version: str | None,
    *,
    max_workers: int = DEFAULT_PROBE_WORKERS,
) -> list[str]:
    """Return candidate arches published on the index for ``package_prefix``.

    Probes run in parallel. If nothing is discovered (e.g. transient index
    issue), fall back to the full candidate list so behaviour is never worse
    than hardcoding every arch.
    """
    if not candidate_arches:
        return []

    candidate_arches = discover_arch_candidates_from_index(
        index_url, package_prefix, candidate_arches
    )

    def probe(arch: str) -> tuple[str, bool]:
        package_name = f"{package_prefix}-{arch}"
        return arch, index_has_package_version(index_url, package_name, version)

    results: dict[str, bool] = {}
    workers = min(max_workers, max(1, len(candidate_arches)))
    with ThreadPoolExecutor(max_workers=workers) as pool:
        futures = [pool.submit(probe, arch) for arch in candidate_arches]
        for future in as_completed(futures):
            arch, available = future.result()
            results[arch] = available

    available = [arch for arch in candidate_arches if results.get(arch)]
    if not available:
        log(
            f"no matching '{package_prefix}-*' package versions discovered; "
            "falling back to the built-in arch list."
        )
        return list(candidate_arches)

    skipped = [arch for arch in candidate_arches if arch not in available]
    if skipped:
        log(
            f"'{package_prefix}' not published for: {', '.join(skipped)} "
            "(skipping these arches)."
        )
    return available


def discover_device_package_arches(
    index_url: str,
    *,
    torch_version: str | None,
    torchvision_version: str | None,
    rocm_version: str | None,
    max_workers: int = DEFAULT_PROBE_WORKERS,
) -> dict[str, list[str]]:
    """Discover torch / torchvision / rocm-sdk device arches from the index."""
    probe = lambda prefix, arches, version: discover_device_arches(
        index_url, prefix, arches, version, max_workers=max_workers
    )
    return {
        "amd_torch_device": probe("amd-torch-device", TORCH_DEVICE_ARCHES, torch_version),
        "amd_torchvision_device": probe(
            "amd-torchvision-device", ROCM_DEVICE_ARCHES, torchvision_version
        ),
        "rocm_sdk_device": probe("rocm-sdk-device", ROCM_DEVICE_ARCHES, rocm_version),
    }


def build_device_package_specs(
    index_url: str,
    *,
    torch_version: str | None,
    torchvision_version: str | None,
    rocm_version: str | None,
    spec_builder: Callable[[str, str | None], str],
) -> list[str]:
    """Return pip specs for discovered device packages."""
    arches = discover_device_package_arches(
        index_url,
        torch_version=torch_version,
        torchvision_version=torchvision_version,
        rocm_version=rocm_version,
    )
    packages = [
        spec_builder(f"amd-torch-device-{arch}", torch_version)
        for arch in arches["amd_torch_device"]
    ]
    packages.extend(
        spec_builder(f"amd-torchvision-device-{arch}", torchvision_version)
        for arch in arches["amd_torchvision_device"]
    )
    packages.extend(
        spec_builder(f"rocm-sdk-device-{arch}", rocm_version)
        for arch in arches["rocm_sdk_device"]
    )
    return packages


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--index-url", default=None)
    parser.add_argument("--torch-version", default=None)
    parser.add_argument("--torchvision-version", default=None)
    parser.add_argument("--rocm-version", default=None)
    parser.add_argument("--workers", type=int, default=DEFAULT_PROBE_WORKERS)
    parser.add_argument(
        "--format",
        choices=("json", "text"),
        default="json",
        help="Output format (default: json)",
    )
    return parser.parse_args()


def main() -> int:
    args = _parse_args()
    index_url = args.index_url or __import__("os").environ.get("INDEX_URL")
    if not index_url:
        log("ERROR: --index-url or INDEX_URL is required")
        return 1

    torch_version = args.torch_version or __import__("os").environ.get("TORCH_VERSION")
    torchvision_version = args.torchvision_version or __import__(
        "os"
    ).environ.get("TORCHVISION_VERSION")
    rocm_version = args.rocm_version or __import__("os").environ.get("ROCM_VERSION")

    discovered = discover_device_package_arches(
        index_url,
        torch_version=torch_version,
        torchvision_version=torchvision_version,
        rocm_version=rocm_version,
        max_workers=args.workers,
    )

    if args.format == "json":
        print(json.dumps(discovered, indent=2))
    else:
        for key, arches in discovered.items():
            print(f"{key}: {','.join(arches)}")

    github_output = __import__("os").environ.get("GITHUB_OUTPUT")
    if github_output:
        with open(github_output, "a", encoding="utf-8") as handle:
            for key, arches in discovered.items():
                handle.write(f"{key}={','.join(arches)}\n")

    return 0


if __name__ == "__main__":
    sys.exit(main())
