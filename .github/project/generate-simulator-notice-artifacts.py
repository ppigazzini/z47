#!/usr/bin/env python3

import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys


XLSXIO_MIT_LICENSE = """Copyright (C) 2016 Brecht Sanders All Rights Reserved

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
\"Software\"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
"""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate simulator notice bundles and SPDX inventories."
    )
    parser.add_argument(
        "--platform", choices=("linux", "macos", "windows"), required=True
    )
    parser.add_argument("--package-dir", required=True)
    parser.add_argument("--upstream-source-repository-url", required=True)
    parser.add_argument("--upstream-source-commit", required=True)
    parser.add_argument("--xlsxio-source-repository-url", default="")
    parser.add_argument("--xlsxio-source-commit", default="")
    return parser.parse_args()


def fail(message: str) -> "None":
    raise RuntimeError(message)


def run_command(command: list[str], *, check: bool = True) -> subprocess.CompletedProcess[str]:
    completed = subprocess.run(
        command,
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if check and completed.returncode != 0:
        joined = " ".join(command)
        fail(f"Command failed ({completed.returncode}): {joined}\n{completed.stderr.strip()}")
    return completed


def command_stdout(command: list[str], *, check: bool = True) -> str:
    return run_command(command, check=check).stdout.strip()


def copy_file(source: Path, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, destination)


def write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def append_package(
    packages: list[dict[str, object]],
    described: list[str],
    *,
    package_id: str,
    name: str,
    download_location: str,
    license_declared: str,
    version_info: str = "",
    summary: str = "",
    license_comments: str = "",
    source_info: str = "",
    homepage: str = "",
    external_ref: str = "",
) -> None:
    package: dict[str, object] = {
        "SPDXID": package_id,
        "name": name,
        "downloadLocation": download_location or "NOASSERTION",
        "filesAnalyzed": False,
        "licenseConcluded": "NOASSERTION",
        "licenseDeclared": license_declared or "NOASSERTION",
        "copyrightText": "NOASSERTION",
    }
    if version_info:
        package["versionInfo"] = version_info
    if summary:
        package["summary"] = summary
    if homepage:
        package["homepage"] = homepage
    if license_comments:
        package["licenseComments"] = license_comments
    if source_info:
        package["sourceInfo"] = source_info
    if external_ref:
        package["externalRefs"] = [
            {
                "referenceCategory": "PACKAGE-MANAGER",
                "referenceType": "purl",
                "referenceLocator": external_ref,
            }
        ]
    packages.append(package)
    described.append(package_id)


def spdx_id(value: str) -> str:
    sanitized = re.sub(r"[^A-Za-z0-9.-]+", "-", value).strip("-")
    if not sanitized:
        sanitized = "unknown"
    return f"SPDXRef-{sanitized}"


def dpkg_field(package_name: str, field_name: str) -> str:
    output = command_stdout(["dpkg-query", "-s", package_name], check=False)
    prefix = f"{field_name}:"
    for line in output.splitlines():
        if line.startswith(prefix):
            return line[len(prefix) :].strip()
    return ""


def pacman_field(package_name: str, field_name: str) -> str:
    output = command_stdout(["pacman", "-Si", package_name], check=False)
    pattern = re.compile(rf"^\s*{re.escape(field_name)}\s*:\s*(.*)$")
    for line in output.splitlines():
        match = pattern.match(line)
        if match:
            return match.group(1).strip()
    return ""


def pacman_version(package_name: str) -> str:
    output = command_stdout(["pacman", "-Q", package_name], check=False)
    parts = output.split(" ", 1)
    return parts[1].strip() if len(parts) == 2 else ""


def ensure_command_exists(command_name: str) -> None:
    if shutil.which(command_name) is None:
        fail(f"Required command is not available on PATH: {command_name}")


def write_common_notice_files(
    *,
    repo_root: Path,
    package_dir: Path,
    notice_root: Path,
    licenses_dir: Path,
    platform: str,
    upstream_source_repository_url: str,
    upstream_source_commit: str,
    xlsxio_source_repository_url: str,
    xlsxio_source_commit: str,
) -> None:
    copying_source = repo_root / "COPYING"
    decnumbericu_source = repo_root / "dep" / "decNumberICU" / "ICU-license.html"
    if not copying_source.is_file():
        fail(f"Required notice source file not found: {copying_source}")
    if not decnumbericu_source.is_file():
        fail(f"Required notice source file not found: {decnumbericu_source}")

    (notice_root / "gpl").mkdir(parents=True, exist_ok=True)
    (notice_root / "decnumbericu").mkdir(parents=True, exist_ok=True)
    (notice_root / "xlsxio").mkdir(parents=True, exist_ok=True)
    licenses_dir.mkdir(parents=True, exist_ok=True)

    copy_file(copying_source, package_dir / "COPYING")
    copy_file(copying_source, notice_root / "gpl" / "COPYING.txt")
    copy_file(decnumbericu_source, notice_root / "decnumbericu" / "ICU-license.html")
    write_text(package_dir / "LICENSE.txt", XLSXIO_MIT_LICENSE)
    write_text(notice_root / "xlsxio" / "LICENSE.txt", XLSXIO_MIT_LICENSE)

    source_manifest = "\n".join(
        [
            f"upstream_url={upstream_source_repository_url}",
            f"upstream_commit={upstream_source_commit}",
            "upstream_license_file=COPYING",
            f"xlsxio_url={xlsxio_source_repository_url}",
            f"xlsxio_commit={xlsxio_source_commit}",
            "xlsxio_license_file=LICENSE.txt",
            f"notice_root=repo-notices/{platform}",
            "",
        ]
    )
    write_text(package_dir / "SOURCE", source_manifest)


def collect_linux_runtime_notices(
    *,
    package_dir: Path,
    notice_root: Path,
    packages: list[dict[str, object]],
    described: list[str],
) -> tuple[str, str, str]:
    ensure_command_exists("dpkg-query")
    ensure_command_exists("readelf")
    ensure_command_exists("ldd")

    inventory_path = notice_root / "LINUX-RUNTIME-LIBRARIES.txt"
    summary_path = notice_root / "LINUX-LIBRARY-NOTICES.txt"
    licenses_dir = notice_root / "licenses"
    licenses_dir.mkdir(parents=True, exist_ok=True)

    elf_paths: list[Path] = []
    for candidate in sorted(path for path in package_dir.rglob("*") if path.is_file()):
        if run_command(["readelf", "-h", str(candidate)], check=False).returncode == 0:
            elf_paths.append(candidate)

    if not elf_paths:
        fail(f"No ELF binaries were found under {package_dir}")

    inventory_lines = ["binary\tlibrary\tpackage\tpackage_version\tlicense_file\thomepage"]
    package_versions: dict[str, str] = {}
    package_urls: dict[str, str] = {}
    package_license_files: dict[str, str] = {}
    package_libraries: dict[str, list[str]] = {}
    seen_library_paths: set[str] = set()
    resolved_pattern = re.compile(r"=>\s+(/[^\s]+)")
    direct_pattern = re.compile(r"^\s*(/[^\s]+)")

    for elf_path in elf_paths:
        ldd_output = command_stdout(["ldd", str(elf_path)], check=False)
        for line in ldd_output.splitlines():
            library_path = ""
            resolved_match = resolved_pattern.search(line)
            if resolved_match:
                library_path = resolved_match.group(1)
            else:
                direct_match = direct_pattern.search(line)
                if direct_match:
                    library_path = direct_match.group(1)
            if not library_path:
                continue
            library_realpath = os.path.realpath(library_path)
            if library_realpath in seen_library_paths or not os.path.isfile(library_realpath):
                continue
            seen_library_paths.add(library_realpath)

            package_lookup = command_stdout(["dpkg-query", "-S", library_realpath], check=False)
            if not package_lookup:
                continue
            package_name = package_lookup.split(": ", 1)[0].strip()
            doc_package = package_name.split(":", 1)[0]

            if package_name not in package_versions:
                package_versions[package_name] = command_stdout(
                    ["dpkg-query", "-W", "-f=${Version}", package_name], check=False
                )
                package_urls[package_name] = dpkg_field(package_name, "Homepage")
                license_source = Path("/usr/share/doc") / doc_package / "copyright"
                if license_source.is_file():
                    copied_path = licenses_dir / doc_package / "copyright"
                    copy_file(license_source, copied_path)
                    package_license_files[package_name] = str(
                        copied_path.relative_to(package_dir).as_posix()
                    )
                else:
                    package_license_files[package_name] = ""
                package_libraries[package_name] = []

            library_name = Path(library_realpath).name
            if library_name not in package_libraries[package_name]:
                package_libraries[package_name].append(library_name)

            inventory_lines.append(
                "\t".join(
                    [
                        elf_path.name,
                        library_name,
                        package_name,
                        package_versions.get(package_name, ""),
                        package_license_files.get(package_name, ""),
                        package_urls.get(package_name, ""),
                    ]
                )
            )

    write_text(inventory_path, "\n".join(inventory_lines) + "\n")

    summary_lines = [
        "Linked runtime library notice summary",
        "",
        f"Generated from ELF dependencies resolved from the packaged files under {package_dir.name}.",
        "",
    ]
    for package_name in sorted(package_versions):
        summary_lines.extend(
            [
                f"Package: {package_name}",
                f"Version: {package_versions.get(package_name, 'unknown') or 'unknown'}",
                f"Homepage: {package_urls.get(package_name, 'unknown') or 'unknown'}",
                "Libraries: "
                + (", ".join(sorted(package_libraries.get(package_name, []))) or "none"),
                "License files: "
                + (package_license_files.get(package_name, "") or "missing"),
                "",
            ]
        )
        append_package(
            packages,
            described,
            package_id=spdx_id(f"linux-{package_name}"),
            name=package_name,
            download_location="NOASSERTION",
            license_declared="NOASSERTION",
            version_info=package_versions.get(package_name, ""),
            summary=(
                "Debian runtime package providing linked shared libraries: "
                + (", ".join(sorted(package_libraries.get(package_name, []))) or "none")
                + "."
            ),
            license_comments=(
                "License text copied from the runner image into "
                + (package_license_files.get(package_name, "") or "missing")
                + "."
            ),
            homepage=package_urls.get(package_name, ""),
        )

    write_text(summary_path, "\n".join(summary_lines))
    return (
        inventory_path.relative_to(package_dir).as_posix(),
        summary_path.relative_to(package_dir).as_posix(),
        (notice_root / "licenses").relative_to(package_dir).as_posix(),
    )


def resolve_windows_source_path(package_dir: Path, packaged_path: Path, mingw_prefix: Path) -> Path | None:
    relative_path = packaged_path.relative_to(package_dir)
    direct_candidate = mingw_prefix / relative_path
    if direct_candidate.exists():
        return direct_candidate
    if relative_path.parent == Path("."):
        bin_candidate = mingw_prefix / "bin" / relative_path.name
        if bin_candidate.exists():
            return bin_candidate
    return None


def collect_windows_runtime_notices(
    *,
    package_dir: Path,
    notice_root: Path,
    packages: list[dict[str, object]],
    described: list[str],
) -> tuple[str, str, str]:
    ensure_command_exists("pacman")
    mingw_prefix = Path(
        os.environ.get("MINGW_PREFIX") or os.environ.get("MSYSTEM_PREFIX") or "/ucrt64"
    )

    inventory_path = notice_root / "WINDOWS-RUNTIME-DLLS.txt"
    summary_path = notice_root / "WINDOWS-DLL-NOTICES.txt"
    licenses_dir = notice_root / "licenses"
    licenses_dir.mkdir(parents=True, exist_ok=True)

    dll_paths = sorted(package_dir.glob("*.dll"))
    if not dll_paths:
        fail(f"No DLLs were found under {package_dir}")

    package_versions: dict[str, str] = {}
    package_licenses: dict[str, str] = {}
    package_urls: dict[str, str] = {}
    package_descriptions: dict[str, str] = {}
    package_license_dirs: dict[str, str] = {}
    package_dlls: dict[str, list[str]] = {}
    dll_owners: dict[str, str] = {}
    dll_owner_versions: dict[str, str] = {}

    def ensure_windows_package_metadata(package_name: str, version_hint: str = "") -> None:
        if not package_name or package_name == "unknown":
            return
        if package_name in package_versions:
            if not package_versions[package_name] and version_hint:
                package_versions[package_name] = version_hint
            return
        package_versions[package_name] = version_hint or pacman_version(package_name)
        package_licenses[package_name] = pacman_field(package_name, "Licenses")
        package_urls[package_name] = pacman_field(package_name, "URL")
        package_descriptions[package_name] = pacman_field(package_name, "Description")
        license_source_dir = mingw_prefix / "share" / "licenses" / package_name
        if license_source_dir.is_dir():
            copied_dir = licenses_dir / package_name
            if copied_dir.exists():
                shutil.rmtree(copied_dir)
            shutil.copytree(license_source_dir, copied_dir)
            package_license_dirs[package_name] = copied_dir.relative_to(package_dir).as_posix()
        else:
            package_license_dirs[package_name] = ""
        package_dlls[package_name] = []

    packaged_files = [
        path
        for path in sorted(package_dir.rglob("*"))
        if path.is_file() and "repo-notices" not in path.parts
    ]
    runtime_packages: set[str] = set()
    for packaged_path in packaged_files:
        source_path = resolve_windows_source_path(package_dir, packaged_path, mingw_prefix)
        if source_path is None:
            continue
        owner = command_stdout(["pacman", "-Qqo", str(source_path)], check=False).splitlines()
        if owner:
            runtime_packages.add(owner[0].strip())

    for package_name in sorted(runtime_packages):
        ensure_windows_package_metadata(package_name)
        if not package_dlls.get(package_name):
            package_dlls[package_name] = []

    inventory_lines = ["dll\tpackage\tpackage_version\tlicenses\tlicense_dir"]
    for dll_path in dll_paths:
        source_path = resolve_windows_source_path(package_dir, dll_path, mingw_prefix)
        owner = "unknown"
        owner_version = ""
        if source_path is not None:
            owner_lines = command_stdout(["pacman", "-Qqo", str(source_path)], check=False).splitlines()
            if owner_lines:
                owner = owner_lines[0].strip()
                owner_version = pacman_version(owner)
                ensure_windows_package_metadata(owner, owner_version)
        dll_owners[dll_path.name] = owner
        dll_owner_versions[dll_path.name] = owner_version
        if owner in package_dlls and dll_path.name not in package_dlls[owner]:
            package_dlls[owner].append(dll_path.name)
        inventory_lines.append(
            "\t".join(
                [
                    dll_path.name,
                    owner,
                    owner_version,
                    package_licenses.get(owner, ""),
                    package_license_dirs.get(owner, ""),
                ]
            )
        )

    write_text(inventory_path, "\n".join(inventory_lines) + "\n")

    summary_lines = [
        "Bundled runtime notice summary",
        "",
        f"Generated from MSYS2-managed runtime files resolved from the packaged Windows artifact under {package_dir.name}.",
        "",
    ]
    for package_name in sorted(package_versions):
        summary_lines.extend(
            [
                f"Package: {package_name}",
                f"Version: {package_versions.get(package_name, 'unknown') or 'unknown'}",
                f"Licenses: {package_licenses.get(package_name, 'unknown') or 'unknown'}",
                f"URL: {package_urls.get(package_name, 'unknown') or 'unknown'}",
                f"Description: {package_descriptions.get(package_name, 'unknown') or 'unknown'}",
                "Packaged runtime files: "
                + (", ".join(sorted(package_dlls.get(package_name, []))) or "non-DLL runtime files"),
                "License files: "
                + (package_license_dirs.get(package_name, "") or "missing"),
                "",
            ]
        )
        append_package(
            packages,
            described,
            package_id=spdx_id(f"msys2-{package_name}"),
            name=package_name,
            download_location=package_urls.get(package_name, "") or "NOASSERTION",
            license_declared="NOASSERTION",
            version_info=package_versions.get(package_name, ""),
            summary=(
                "MSYS2 package providing bundled Windows runtime files: "
                + (", ".join(sorted(package_dlls.get(package_name, []))) or "non-DLL runtime files")
                + "."
            ),
            license_comments=(
                "License files copied to "
                + (package_license_dirs.get(package_name, "") or "missing")
                + "."
            ),
            source_info=package_descriptions.get(package_name, ""),
            homepage=package_urls.get(package_name, ""),
            external_ref=(
                f"pkg:generic/{package_name}@{package_versions.get(package_name, 'unknown') or 'unknown'}"
            ),
        )

    for dll_name in sorted(dll_owners):
        append_package(
            packages,
            described,
            package_id=spdx_id(f"windows-dll-{dll_name}"),
            name=dll_name,
            download_location="NOASSERTION",
            license_declared="NOASSERTION",
            version_info=dll_owner_versions.get(dll_name, ""),
            summary="Bundled runtime DLL copied into the packaged Windows simulator artifact.",
            source_info=f"Owned by {dll_owners.get(dll_name, 'unknown')}.",
        )

    write_text(summary_path, "\n".join(summary_lines))
    return (
        inventory_path.relative_to(package_dir).as_posix(),
        summary_path.relative_to(package_dir).as_posix(),
        licenses_dir.relative_to(package_dir).as_posix(),
    )


def collect_macos_runtime_notices(
    *,
    package_dir: Path,
    notice_root: Path,
    packages: list[dict[str, object]],
    described: list[str],
) -> tuple[str, str, str]:
    ensure_command_exists("brew")
    ensure_command_exists("otool")

    inventory_path = notice_root / "MACOS-RUNTIME-LIBRARIES.txt"
    summary_path = notice_root / "MACOS-LIBRARY-NOTICES.txt"
    licenses_dir = notice_root / "licenses"
    licenses_dir.mkdir(parents=True, exist_ok=True)

    brew_prefix = command_stdout(["brew", "--prefix"])
    cellar_prefix = command_stdout(["brew", "--cellar"])
    info_cache: dict[str, dict[str, object]] = {}

    def brew_info(formula_name: str) -> dict[str, object]:
        if formula_name in info_cache:
            return info_cache[formula_name]
        output = command_stdout(["brew", "info", "--json=v2", formula_name], check=False)
        if not output:
            info_cache[formula_name] = {}
            return info_cache[formula_name]
        payload = json.loads(output)
        formulae = payload.get("formulae") or []
        info_cache[formula_name] = formulae[0] if formulae else {}
        return info_cache[formula_name]

    def brew_license(formula_name: str) -> str:
        info = brew_info(formula_name)
        licenses = info.get("licenses")
        if isinstance(licenses, list):
            return " OR ".join(str(item) for item in licenses if item)
        if isinstance(licenses, str):
            return licenses
        license_value = info.get("license")
        if isinstance(license_value, str):
            return license_value
        return ""

    def brew_homepage(formula_name: str) -> str:
        info = brew_info(formula_name)
        homepage = info.get("homepage")
        return homepage if isinstance(homepage, str) else ""

    def brew_version(formula_name: str) -> str:
        info = brew_info(formula_name)
        installed = info.get("installed")
        if isinstance(installed, list) and installed:
            installed_version = installed[0].get("version")
            if isinstance(installed_version, str):
                return installed_version
        versions = info.get("versions")
        if isinstance(versions, dict):
            stable_version = versions.get("stable")
            if isinstance(stable_version, str):
                return stable_version
        return ""

    macho_paths: list[Path] = []
    for candidate in sorted(path for path in package_dir.rglob("*") if path.is_file()):
        if run_command(["otool", "-hV", str(candidate)], check=False).returncode == 0:
            macho_paths.append(candidate)

    if not macho_paths:
        fail(f"No Mach-O binaries were found under {package_dir}")

    formula_versions: dict[str, str] = {}
    formula_licenses: dict[str, str] = {}
    formula_urls: dict[str, str] = {}
    formula_metadata_files: dict[str, str] = {}
    formula_libraries: dict[str, list[str]] = {}
    seen_library_paths: set[str] = set()
    inventory_lines = [
        "binary\tlibrary\tformula\tformula_version\tlicense\tmetadata_file\thomepage"
    ]

    for macho_path in macho_paths:
        output = command_stdout(["otool", "-L", str(macho_path)], check=False)
        for line in output.splitlines()[1:]:
            stripped = line.strip()
            if not stripped:
                continue
            library_path = stripped.split(" ", 1)[0]
            if (
                library_path.startswith("@")
                or library_path.startswith("/System/Library/")
                or library_path.startswith("/usr/lib/")
            ):
                continue
            if not (
                library_path.startswith(f"{cellar_prefix}/")
                or library_path.startswith(f"{brew_prefix}/opt/")
                or library_path.startswith(f"{brew_prefix}/Cellar/")
            ):
                continue
            if library_path in seen_library_paths:
                continue
            seen_library_paths.add(library_path)

            formula_name = ""
            formula_version = ""
            if library_path.startswith(f"{cellar_prefix}/"):
                relative_path = library_path[len(cellar_prefix) + 1 :]
                parts = relative_path.split("/")
                if len(parts) >= 2:
                    formula_name = parts[0]
                    formula_version = parts[1]
            elif library_path.startswith(f"{brew_prefix}/Cellar/"):
                relative_path = library_path[len(brew_prefix) + len("/Cellar/") :]
                parts = relative_path.split("/")
                if len(parts) >= 2:
                    formula_name = parts[0]
                    formula_version = parts[1]
            elif library_path.startswith(f"{brew_prefix}/opt/"):
                relative_path = library_path[len(brew_prefix) + len("/opt/") :]
                parts = relative_path.split("/")
                if parts:
                    formula_name = parts[0]

            if not formula_name:
                continue
            if formula_name not in formula_versions:
                formula_versions[formula_name] = formula_version or brew_version(formula_name)
                formula_licenses[formula_name] = brew_license(formula_name)
                formula_urls[formula_name] = brew_homepage(formula_name)
                metadata_path = licenses_dir / formula_name / "HOMEBREW-METADATA.txt"
                metadata_text = "\n".join(
                    [
                        f"formula={formula_name}",
                        f"version={formula_versions[formula_name]}",
                        f"homepage={formula_urls[formula_name]}",
                        f"license={formula_licenses[formula_name]}",
                        "source=brew info --json=v2",
                        "",
                    ]
                )
                write_text(metadata_path, metadata_text)
                formula_metadata_files[formula_name] = metadata_path.relative_to(package_dir).as_posix()
                formula_libraries[formula_name] = []

            library_name = Path(library_path).name
            if library_name not in formula_libraries[formula_name]:
                formula_libraries[formula_name].append(library_name)
            inventory_lines.append(
                "\t".join(
                    [
                        macho_path.name,
                        library_name,
                        formula_name,
                        formula_versions.get(formula_name, ""),
                        formula_licenses.get(formula_name, ""),
                        formula_metadata_files.get(formula_name, ""),
                        formula_urls.get(formula_name, ""),
                    ]
                )
            )

    write_text(inventory_path, "\n".join(inventory_lines) + "\n")

    summary_lines = [
        "Linked macOS runtime library notice summary",
        "",
        f"Generated from Homebrew-linked libraries resolved from the packaged files under {package_dir.name}.",
        "",
    ]
    if not formula_versions:
        summary_lines.extend(
            [
                "No Homebrew-linked runtime libraries were resolved from the packaged simulator files.",
                "",
            ]
        )
    for formula_name in sorted(formula_versions):
        summary_lines.extend(
            [
                f"Formula: {formula_name}",
                f"Version: {formula_versions.get(formula_name, 'unknown') or 'unknown'}",
                f"License: {formula_licenses.get(formula_name, 'unknown') or 'unknown'}",
                f"Homepage: {formula_urls.get(formula_name, 'unknown') or 'unknown'}",
                "Libraries: "
                + (", ".join(sorted(formula_libraries.get(formula_name, []))) or "none"),
                "Metadata file: "
                + (formula_metadata_files.get(formula_name, "") or "missing"),
                "",
            ]
        )
        append_package(
            packages,
            described,
            package_id=spdx_id(f"macos-{formula_name}"),
            name=formula_name,
            download_location=formula_urls.get(formula_name, "") or "NOASSERTION",
            license_declared=formula_licenses.get(formula_name, "") or "NOASSERTION",
            version_info=formula_versions.get(formula_name, ""),
            summary=(
                "Homebrew formula providing linked macOS runtime libraries: "
                + (", ".join(sorted(formula_libraries.get(formula_name, []))) or "none")
                + "."
            ),
            license_comments=(
                "Formula metadata recorded in "
                + (formula_metadata_files.get(formula_name, "") or "missing")
                + "."
            ),
            homepage=formula_urls.get(formula_name, ""),
            external_ref=(
                f"pkg:generic/{formula_name}@{formula_versions.get(formula_name, 'unknown') or 'unknown'}"
            ),
        )

    write_text(summary_path, "\n".join(summary_lines))
    return (
        inventory_path.relative_to(package_dir).as_posix(),
        summary_path.relative_to(package_dir).as_posix(),
        licenses_dir.relative_to(package_dir).as_posix(),
    )


def write_notice_summary(
    *,
    package_dir: Path,
    notice_root: Path,
    platform: str,
    upstream_source_repository_url: str,
    upstream_source_commit: str,
    xlsxio_source_repository_url: str,
    xlsxio_source_commit: str,
    runtime_inventory_file: str,
    runtime_summary_file: str,
    runtime_license_dir: str,
) -> None:
    summary_path = notice_root / "NOTICE-SUMMARY.txt"
    lines = [
        f"Simulator notice bundle for the {platform} GitHub CI artifact.",
        "",
        "Package source provenance:",
        f"- upstream_url={upstream_source_repository_url}",
        f"- upstream_commit={upstream_source_commit}",
        f"- xlsxio_url={xlsxio_source_repository_url or 'unknown'}",
        f"- xlsxio_commit={xlsxio_source_commit or 'unknown'}",
        "",
        "Included notice files:",
        "- COPYING",
        "- LICENSE.txt",
        f"- repo-notices/{platform}/gpl/COPYING.txt",
        f"- repo-notices/{platform}/decnumbericu/ICU-license.html",
        f"- repo-notices/{platform}/xlsxio/LICENSE.txt",
        f"- {runtime_inventory_file}",
        f"- {runtime_summary_file}",
        "",
        "Runtime package notice directory:",
        f"- {runtime_license_dir}",
        "",
    ]
    write_text(summary_path, "\n".join(lines))


def main() -> int:
    args = parse_args()
    package_dir = Path(args.package_dir).resolve()
    if not package_dir.is_dir():
        fail(f"Package directory not found: {package_dir}")

    repo_root = Path(__file__).resolve().parents[2]
    notice_root = package_dir / "repo-notices" / args.platform
    licenses_dir = notice_root / "licenses"

    packages: list[dict[str, object]] = []
    described: list[str] = []

    write_common_notice_files(
        repo_root=repo_root,
        package_dir=package_dir,
        notice_root=notice_root,
        licenses_dir=licenses_dir,
        platform=args.platform,
        upstream_source_repository_url=args.upstream_source_repository_url,
        upstream_source_commit=args.upstream_source_commit,
        xlsxio_source_repository_url=args.xlsxio_source_repository_url,
        xlsxio_source_commit=args.xlsxio_source_commit,
    )

    append_package(
        packages,
        described,
        package_id=spdx_id("z47-upstream-core"),
        name="z47-upstream-core",
        download_location=args.upstream_source_repository_url,
        license_declared="GPL-3.0-only",
        version_info=args.upstream_source_commit,
        summary="Authoritative upstream core revision synchronized into the packaged simulator artifact.",
        license_comments=f"Overall package license text is shipped as COPYING and repo-notices/{args.platform}/gpl/COPYING.txt.",
        source_info="Recorded from the workflow upstream resolution step.",
    )
    append_package(
        packages,
        described,
        package_id=spdx_id("decnumbericu"),
        name="decNumberICU",
        download_location=args.upstream_source_repository_url,
        license_declared="ICU",
        version_info=args.upstream_source_commit,
        summary="Vendored decimal arithmetic support shipped from the synchronized upstream source tree.",
        license_comments=f"Notice copied to repo-notices/{args.platform}/decnumbericu/ICU-license.html.",
        source_info="Notice source is dep/decNumberICU/ICU-license.html in the synchronized upstream checkout.",
    )
    append_package(
        packages,
        described,
        package_id=spdx_id("xlsxio"),
        name="xlsxio",
        download_location=args.xlsxio_source_repository_url or "NOASSERTION",
        license_declared="MIT",
        version_info=args.xlsxio_source_commit or "unknown",
        summary="Spreadsheet I/O dependency recorded in the simulator package provenance and notices.",
        license_comments=f"Notice copied to LICENSE.txt and repo-notices/{args.platform}/xlsxio/LICENSE.txt.",
        source_info="Version and source URL come from the host workflow inputs.",
    )

    if args.platform == "linux":
        runtime_inventory_file, runtime_summary_file, runtime_license_dir = collect_linux_runtime_notices(
            package_dir=package_dir,
            notice_root=notice_root,
            packages=packages,
            described=described,
        )
    elif args.platform == "macos":
        runtime_inventory_file, runtime_summary_file, runtime_license_dir = collect_macos_runtime_notices(
            package_dir=package_dir,
            notice_root=notice_root,
            packages=packages,
            described=described,
        )
    else:
        runtime_inventory_file, runtime_summary_file, runtime_license_dir = collect_windows_runtime_notices(
            package_dir=package_dir,
            notice_root=notice_root,
            packages=packages,
            described=described,
        )

    write_notice_summary(
        package_dir=package_dir,
        notice_root=notice_root,
        platform=args.platform,
        upstream_source_repository_url=args.upstream_source_repository_url,
        upstream_source_commit=args.upstream_source_commit,
        xlsxio_source_repository_url=args.xlsxio_source_repository_url,
        xlsxio_source_commit=args.xlsxio_source_commit,
        runtime_inventory_file=runtime_inventory_file,
        runtime_summary_file=runtime_summary_file,
        runtime_license_dir=runtime_license_dir,
    )

    spdx_document = {
        "spdxVersion": "SPDX-2.3",
        "dataLicense": "CC0-1.0",
        "SPDXID": "SPDXRef-DOCUMENT",
        "name": f"z47 {args.platform} simulator third-party inventory",
        "documentNamespace": f"https://z47.invalid/spdx/{args.platform}/{args.upstream_source_commit}",
        "creationInfo": {
            "created": command_stdout(["date", "-u", "+%Y-%m-%dT%H:%M:%SZ"]),
            "creators": ["Tool: generate-simulator-notice-artifacts.py"],
        },
        "documentDescribes": described,
        "packages": packages,
    }
    write_text(package_dir / "THIRD-PARTY.spdx.json", json.dumps(spdx_document, indent=2) + "\n")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except RuntimeError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        raise SystemExit(1)