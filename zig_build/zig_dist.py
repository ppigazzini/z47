#!/usr/bin/env python3

from __future__ import annotations

import os
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
UPSTREAM_PIN_PATH = REPO_ROOT / ".github/project/upstream-pin.env"


def load_upstream_root_value() -> str:
    override = os.environ.get("UPSTREAM_ROOT")
    if override:
        return override

    try:
        for raw_line in UPSTREAM_PIN_PATH.read_text(encoding="utf-8").splitlines():
            line = raw_line.strip()
            if not line or line.startswith("#"):
                continue
            if line.startswith("UPSTREAM_ROOT="):
                return line.split("=", 1)[1].strip()
    except OSError as exc:
        raise SystemExit(f"unable to read upstream pin file {UPSTREAM_PIN_PATH}: {exc}") from exc

    raise SystemExit(f"missing UPSTREAM_ROOT in {UPSTREAM_PIN_PATH}")


def resolve_repo_relative(path_value: str) -> Path:
    path = Path(path_value)
    if not path.is_absolute():
        path = REPO_ROOT / path
    return path.resolve()


UPSTREAM_ROOT = load_upstream_root_value()
UPSTREAM_SOURCE_ROOT = REPO_ROOT if UPSTREAM_ROOT == "." else resolve_repo_relative(UPSTREAM_ROOT)
WIKI_URL = "https://gitlab.com/rpncalculators/c43.wiki.git"
DIST_DOCS_DIR = UPSTREAM_SOURCE_ROOT / "res/dist-docs"

# Distribution archives need stable install notes even when CI has no checked-in
# dist-doc overrides and no live wiki checkout.
EMBEDDED_DIST_DOCS = {
     "Installation-on-Windows.md": """\
This generated copy is packaged by the Zig-owned distribution helper so CI does not depend on a checked-in wiki export.

[Original Wiki](https://gitlab.com/h2x/c47-wiki/-/wikis/Installation-on-Windows-%28old%29)

[New Wiki](https://gitlab.com/h2x/c47-wiki/-/wikis/Installation-On-Windows)
""",
     "Installation-on-a-DM42.md": """\
To change the firmware on a DM42, use the following instructions. _Warning:_ use the C47 program for DM42 at your own risk.

This generated copy is packaged by the Zig-owned distribution helper so CI does not depend on a checked-in wiki export.

The instructions below are valid, but are better described in the new Wiki https://gitlab.com/h2x/c47-wiki/-/wikis/installing-c47-on-a-dm42.

## Updating the DMCP Firmware

The C47 firmware requires a recent version of the DMCP firmware. If you have never updated this for your calculator (or have not updated this recently) then this should be updated first.

1. Start your computer. Take a DM42 and turn it on; then
    - if you are using DM42 firmware: press [Setup] [5] (System) [2] (Enter system menu) [4] (Reset to DMCP menu)
    - if you are using a previous version of C47 firmware: press [fMODE] [fDMCP]
    - Now connect your computer to the calculator micro-USB socket using a suitable data cable. Ensure it connects properly on the calculator side - cutting back the plastic edge a bit may be necessary.
    - Press [6] (Activate USB Disk). The flash disk of your DM42 should show up as an external mass storage volume on your computer now.
2. Start the internet browser on your computer and go to [the SwissMicros firmware website](https://technical.swissmicros.com/dm42/firmware/).
    - Download the most recent file within the `DMCP` directory (this should be named DMCP_flash_n.nn.bin") and copy this to the DM42 flash disk.
    - Alternatively, follow the steps below to re-install a full working DM42 first in order to update to the latest versions.
3. 'Eject' the USB disk from the operating system, and do not press [EXIT] on the calculator as instructed. Pressing [EXIT] will sometimes cause loss of data on the DM42 USB disk.
4. The DMCP firmware will automatically detect the update. Press [ENTER] to continue upgrading the DMCP.
5. After a few seconds the firmware will be complete. Press [EXIT] to continue.

## Convert a DM42 to a C47

1. Start your computer. Take a DM42 and turn it on; then
    - press [Setup] [5] (System) [2] (Enter system menu) [4] (Reset to DMCP menu)
    - Now connect your computer to the calculator micro-USB socket using a suitable data cable. Ensure it connects properly on the calculator side - cutting back the cable socket's plastic edge a bit may be necessary.
    - Press [6] (Activate USB Disk). The flash disk of your DM42 should show up as an external mass storage volume on your computer now.
2. Download the [latest release](https://47calc.com) of C47 for DM42.
    - Copy the files `C47.pgm` and `C47_qspi.bin` to the DM42 flash disk.
    - Option: Copying `testPgms.bin` to the DM42 flash disk will give you some test programs pre-entered.
    - Option: If your donor calculator is a WP43, you will need to load the original DM42 keymap file. Copy the file `keymap_DM42.bin` to `keymap.bin` to the DM42 flash disk. This will restore all keys to match the C47 internal layout and allow you to choose the WP43 profile from the calculator's KEYS menu later.
    - Delete any other files ending `_qspi.bin` or `.pgm` because the calculator may attempt to load those instead of the C47 firmware.
3. 'Eject' the USB disk from the operating system, and do not press [EXIT] on the calculator as instructed. Pressing [EXIT] will sometimes cause loss of data on the DM42 USB disk.
4. Press [4] (Load QSPI from FAT). This will automatically detect the relevant file and flash it to the DM42. It should be completed in seconds.
    - Press any key to restart followed by [EXIT] [3] (DMCP Menu).
5. Should your calculator crash or not respond at this point, it will be due to the incompatibility of the (new) qspi file to the (old) firmware pgm file. The solution to recover to the DMCP menu is to press F1 while you use a pin to press the rear RESET button. Then, proceed as below.
6. Press [3] (Load Program) and select `C47.pgm`. Wait about 15s for flashing to complete and follow on screen instructions to reboot if needed.

See [the download page](https://47calc.com) for further details on how to order a key template or produce a custom overlay and stickers to make it easier to use your C47 calculator.

## Update C47 to the latest version

1. Start your computer. Take your C47 DM42 and turn it on; then
    - press [fMODE] [fDMCP] or press [fMODE] [fActUSB] which is a faster direct way to access the drive.
    - Now connect your computer to the calculator micro-USB socket using a suitable data cable. Ensure it connects properly on the calculator side - cutting back the plastic edge a bit may be necessary.
    - After [fDMCP] press [6] (Activate USB Disk). The flash disk of your DM42 should show up as an external mass storage volume on your computer now. (The [fActUSB] step reaches here without (6.)).
2. Download the [latest release](https://47calc.com) of C47 for DM42.
    - Copy the files `C47.pgm` and `C47_qspi.bin` to the DM42 flash disk.
    - Option: Copying `testPgms.bin` to the DM42 flash disk will give you some test programs pre-entered.
    - Option: If your donor calculator is a WP43, you will need to load the original DM42 keymap file. Copy the file `keymap_DM42.bin` to `keymap.bin` to the DM42 flash disk. This will restore all keys to match the C47 internal layout.
    - Delete any other files ending `_qspi.bin` or `.pgm` because the calculator may attempt to load those instead of the WP43, or WP34S, DB48X firmware.
3. 'Eject' the USB disk from the operating system, and do not press [EXIT] on the calculator as instructed. Pressing [EXIT] will sometimes cause loss of data on the DM42 USB disk.
4. Press [4] (Load QSPI from FAT). This will automatically detect the relevant file and flash it to the DM42. It should be completed in seconds.
    - Press any key to restart followed by [EXIT] [3] (DMCP Menu).
5. Should your calculator crash or not respond at this point, it will be due to the incompatibility of the (new) qspi file to the (old) firmware pgm file. The solution to recover to the DMCP menu is to press F1 while you use a pin to press the rear RESET button. Then, proceed as below.
6. Press [3] (Load Program) and select `C47.pgm`. Wait about 15s for flashing to complete and follow on screen instructions to reboot if needed.

## Converting a DM42 calculator running C47 back to a DM42

1. Start your computer. Take the DM42 calculator running C47 and turn it on; then
    - press [gMODE] [gDMCP]
    - Now connect your computer to the calculator micro-USB socket using a suitable data cable. Ensure it connects properly on the calculator side - cutting back the plastic edge a bit may be necessary.
    - Press [6] (Activate USB Disk). The flash disk of your DM42 should show up as an external mass storage volume on your computer now.
2. Start the internet browser on your computer and go to [the SwissMicros firmware website](https://technical.swissmicros.com/dm42/firmware/).
    - Download the most recent file beginning `DM42` and ending `.pgm` in that directory. It is advisable to alternatively use the 'combo' file, marked 'as such'DMCP OS + DM42 program combo' on the SM folder, to install both the DMCP os and DM42 pgm simultaneously.
    - Download the most recent file in the `qspi_data` subdirectory beginning `DM42_qspi` and ending `.bin`.
    - Copy these both to the DM42 flash disk.
    - Delete any other files ending `_qspi.bin` or `.pgm` because the calculator may attempt to load those instead of the DM42 firmware.
3. 'Eject' the USB disk from the operating system, and do not press [EXIT] on the calculator as instructed. Pressing [EXIT] will sometimes cause loss of data on the DM42 USB disk.
4. Press [4] (Load QSPI from FAT). This will automatically detect the relevant file and flash it to the DM42. It should be completed in seconds.
    - Press any key to restart followed by [EXIT] [3] (DMCP Menu).
5. Should your calculator crash or not respond at this point, it will be due to the incompatibility of the (new) qspi file to the (old) firmware pgm file. The solution to recover to the DMCP menu is to press F1 while you use a pin to press the rear RESET button. Then, proceed as below.
6. Press [3] (Load Program) and select `DM42_n.nn.pgm`. Wait about 15s for flashing to complete and follow on screen instructions to reboot if needed.
""",
}

OFFIMG_DIRS = [
    UPSTREAM_SOURCE_ROOT / "res/offimg/Egypt",
    UPSTREAM_SOURCE_ROOT / "res/offimg/Norway",
    UPSTREAM_SOURCE_ROOT / "res/offimg/Netherlands",
    UPSTREAM_SOURCE_ROOT / "res/offimg/From WP43",
    UPSTREAM_SOURCE_ROOT / "res/offimg/General",
    UPSTREAM_SOURCE_ROOT / "res/offimg/HP related",
    UPSTREAM_SOURCE_ROOT / "res/offimg/C47",
]


def fail(message: str) -> "NoReturn":
    raise SystemExit(message)


def ensure_clean_dir(path: Path) -> None:
    if path.exists():
        shutil.rmtree(path)
    path.mkdir(parents=True, exist_ok=True)


def copy_file(src: Path, dst: Path) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)


def copy_tree(src: Path, dst: Path) -> None:
    if dst.exists():
        shutil.rmtree(dst)
    shutil.copytree(src, dst)


def copy_tree_contents(src: Path, dst: Path) -> None:
    dst.mkdir(parents=True, exist_ok=True)
    for entry in src.iterdir():
        target = dst / entry.name
        if entry.is_dir():
            if target.exists():
                shutil.rmtree(target)
            shutil.copytree(entry, target)
        else:
            shutil.copy2(entry, target)


def zip_tree(zip_path: Path, root: Path, arc_root: str) -> None:
    zip_path.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for entry in sorted(root.rglob("*")):
            if entry.is_dir():
                continue
            archive.write(entry, (Path(arc_root) / entry.relative_to(root)).as_posix())


def zip_file(zip_path: Path, file_path: Path, arcname: str) -> None:
    zip_path.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        archive.write(file_path, arcname)


def run_command(argv: list[str], cwd: Path | None = None) -> None:
    subprocess.run(argv, cwd=cwd, check=True)


def clone_wiki(output_dir: Path) -> None:
    shutil.rmtree(output_dir, ignore_errors=True)
    output_dir.parent.mkdir(parents=True, exist_ok=True)
    run_command(["git", "clone", "--depth", "1", WIKI_URL, str(output_dir)])


def write_dist_doc(filename: str, dst: Path, wiki_dir: Path | None = None) -> None:
    searched: list[Path] = []
    if wiki_dir is not None:
        candidate = wiki_dir / filename
        searched.append(candidate)
        if candidate.exists():
            copy_file(candidate, dst)
            return
    candidate = DIST_DOCS_DIR / filename
    searched.append(candidate)
    if candidate.exists():
        copy_file(candidate, dst)
        return
    embedded = EMBEDDED_DIST_DOCS.get(filename)
    if embedded is not None:
        dst.parent.mkdir(parents=True, exist_ok=True)
        dst.write_text(embedded, encoding="utf-8")
        return
    checked = ", ".join(str(path) for path in searched)
    fail(f"missing distribution document: {filename}; checked {checked}")


def stage_host_resources(stage_dir: Path, c47_bin: Path, r47_bin: Path | None = None) -> None:
    copy_file(c47_bin, stage_dir / c47_bin.name)
    if r47_bin is not None:
        copy_file(r47_bin, stage_dir / r47_bin.name)
    copy_tree(UPSTREAM_SOURCE_ROOT / "res/PROGRAMS", stage_dir / "res/PROGRAMS")
    copy_tree(UPSTREAM_SOURCE_ROOT / "res/STATE", stage_dir / "res/STATE")
    copy_file(UPSTREAM_SOURCE_ROOT / "res/c47_pre.css", stage_dir / "res/c47_pre.css")
    copy_file(UPSTREAM_SOURCE_ROOT / "res/C47.png", stage_dir / "res/C47.png")
    copy_file(UPSTREAM_SOURCE_ROOT / "res/C47short.png", stage_dir / "res/C47short.png")
    copy_file(UPSTREAM_SOURCE_ROOT / "res/R47.png", stage_dir / "res/R47.png")
    copy_file(UPSTREAM_SOURCE_ROOT / "res/R47short.png", stage_dir / "res/R47short.png")
    copy_file(UPSTREAM_SOURCE_ROOT / "res/fonts/C47__StandardFont.ttf", stage_dir / "C47__StandardFont.ttf")


def copy_testpgms_bundle(stage_dir: Path, testpgms_bin: Path, testpgms_txt: Path, testpgms_zip: Path, subdir: str) -> None:
    target = stage_dir / subdir
    target.mkdir(parents=True, exist_ok=True)
    copy_file(testpgms_bin, target / "testPgms.bin")
    copy_file(testpgms_txt, target / "testPgms.txt")
    copy_file(testpgms_zip, target / "testPgms.zip")


def run_exportall(c47_bin: Path, cwd: Path) -> None:
    command = [str(c47_bin), "--writeexportall"]
    if sys.platform.startswith("linux") and not ("DISPLAY" in os.environ or "WAYLAND_DISPLAY" in os.environ):
        xvfb = shutil.which("xvfb-run")
        if xvfb is not None:
            command = [xvfb, "-a", *command]
    run_command(command, cwd=cwd)


def make_testpgms_zip(zip_out: Path, c47_bin: Path, testpgms_bin: Path, testpgms_txt: Path) -> None:
    stage_dir = zip_out.parent / (zip_out.stem + ".stage")
    ensure_clean_dir(stage_dir)
    stage_host_resources(stage_dir, c47_bin)
    testpgms_dir = stage_dir / "res/testPgms"
    testpgms_dir.mkdir(parents=True, exist_ok=True)
    copy_file(testpgms_bin, testpgms_dir / "testPgms.bin")
    copy_file(testpgms_txt, testpgms_dir / "testPgms.txt")
    run_exportall(stage_dir / c47_bin.name, stage_dir)
    programs_dir = stage_dir / "PROGRAMS/ALLPGMS"
    if not programs_dir.exists():
        fail("expected PROGRAMS/ALLPGMS after --writeexportall")
    zip_tree(zip_out, programs_dir, "ALLPGMS")
    shutil.rmtree(stage_dir)


def package_host(flavor: str, zip_out: Path, stage_name: str, c47_bin: Path, r47_bin: Path, testpgms_bin: Path, testpgms_txt: Path, testpgms_zip: Path, wiki_dir: Path | None) -> None:
    stage_dir = zip_out.parent / stage_name
    ensure_clean_dir(stage_dir)
    stage_host_resources(stage_dir, c47_bin, r47_bin)
    copy_testpgms_bundle(stage_dir, testpgms_bin, testpgms_txt, testpgms_zip, "res/testPgms")

    if flavor == "windows":
        tone_dir = stage_dir / "res/tone"
        tone_dir.mkdir(parents=True, exist_ok=True)
        for wav in sorted((UPSTREAM_SOURCE_ROOT / "res/tone").glob("*.wav")):
            copy_file(wav, tone_dir / wav.name)
        copy_file(UPSTREAM_SOURCE_ROOT / "res/c47.reg", stage_dir / "c47.reg")
        copy_file(UPSTREAM_SOURCE_ROOT / "res/c47.cmd", stage_dir / "c47.cmd")
        write_dist_doc("Installation-on-Windows.md", stage_dir / "readme.txt", wiki_dir)
    elif flavor == "linux":
        strip_tool = shutil.which("strip")
        if strip_tool is not None:
            for host_bin in (c47_bin, r47_bin):
                run_command([strip_tool, str(stage_dir / host_bin.name)])
        copy_file(UPSTREAM_SOURCE_ROOT / "res/c47.xpm", stage_dir / "res/c47.xpm")
    elif flavor == "macos":
        strip_tool = shutil.which("strip")
        if strip_tool is not None:
            for host_bin in (c47_bin, r47_bin):
                run_command([strip_tool, str(stage_dir / host_bin.name)])
    else:
        fail(f"unsupported host package flavor: {flavor}")

    zip_tree(zip_out, stage_dir, stage_name)
    shutil.rmtree(stage_dir)


def prepare_dm_base(stage_dir: Path, testpgms_bin: Path, testpgms_txt: Path, testpgms_zip: Path) -> None:
    resources_dir = stage_dir / "resources"
    resources_dir.mkdir(parents=True, exist_ok=True)
    offimg_dir = stage_dir / "offimg"
    for offimg_source in OFFIMG_DIRS:
        copy_tree_contents(offimg_source, offimg_dir)
    copy_tree(UPSTREAM_SOURCE_ROOT / "res/PROGRAMS", stage_dir / "PROGRAMS")
    copy_tree(UPSTREAM_SOURCE_ROOT / "res/STATE", stage_dir / "STATE")
    copy_file(UPSTREAM_SOURCE_ROOT / "res/keymaps/keymap_DM42.bin", resources_dir / "keymap_DM42.bin")
    copy_testpgms_bundle(stage_dir, testpgms_bin, testpgms_txt, testpgms_zip, "resources")


def package_dmcp(zip_out: Path, stage_name: str, program: Path, qspi: Path, map_file: Path, testpgms_bin: Path, testpgms_txt: Path, testpgms_zip: Path, wiki_dir: Path | None, include_packages: bool) -> None:
    stage_dir = zip_out.parent / stage_name
    ensure_clean_dir(stage_dir)
    prepare_dm_base(stage_dir, testpgms_bin, testpgms_txt, testpgms_zip)
    copy_file(program, stage_dir / program.name)
    copy_file(qspi, stage_dir / qspi.name)
    zip_file(stage_dir / "resources/C47.map.zip", map_file, map_file.name)
    write_dist_doc("Installation-on-a-DM42.md", stage_dir / "install_C47_on_DM42_readme_on_wiki.txt", wiki_dir)
    if include_packages:
        copy_file(UPSTREAM_SOURCE_ROOT / "res/PACKAGES.md", stage_dir / "PACKAGES.txt")
    zip_tree(zip_out, stage_dir, stage_name)
    shutil.rmtree(stage_dir)


def package_dmcpr47(zip_out: Path, stage_name: str, program: Path, qspi: Path, map_file: Path, testpgms_bin: Path, testpgms_txt: Path, testpgms_zip: Path, wiki_dir: Path | None) -> None:
    stage_dir = zip_out.parent / stage_name
    ensure_clean_dir(stage_dir)
    prepare_dm_base(stage_dir, testpgms_bin, testpgms_txt, testpgms_zip)
    copy_file(program, stage_dir / program.name)
    copy_file(qspi, stage_dir / qspi.name)
    copy_file(UPSTREAM_SOURCE_ROOT / "res/keymaps/keymap_R47.bin", stage_dir / "keymap_R47.bin")
    zip_file(stage_dir / "resources/R47.map.zip", map_file, map_file.name)
    write_dist_doc("Installation-on-a-DM42.md", stage_dir / "install_C47_on_DM42_readme_on_wiki.txt", wiki_dir)
    zip_tree(zip_out, stage_dir, stage_name)
    shutil.rmtree(stage_dir)


def package_dmcp5(zip_out: Path, stage_name: str, program: Path, map_file: Path, testpgms_bin: Path, testpgms_txt: Path, testpgms_zip: Path) -> None:
    stage_dir = zip_out.parent / stage_name
    ensure_clean_dir(stage_dir)
    prepare_dm_base(stage_dir, testpgms_bin, testpgms_txt, testpgms_zip)
    copy_file(program, stage_dir / program.name)
    copy_file(UPSTREAM_SOURCE_ROOT / "res/dmcp5/SwissMicros/DM42_qspi_3.x.bin", stage_dir / "resources/DM42_qspi_3.x.bin")
    zip_file(stage_dir / "resources/C47.map.zip", map_file, map_file.name)
    copy_file(UPSTREAM_SOURCE_ROOT / "res/dmcp5/install_C47_on_DM42n.txt", stage_dir / "install_C47_on_DM42n.txt")
    copy_file(UPSTREAM_SOURCE_ROOT / "res/PACKAGES.md", stage_dir / "PACKAGES.txt")
    zip_tree(zip_out, stage_dir, stage_name)
    shutil.rmtree(stage_dir)


def package_dmcp5r47(zip_out: Path, stage_name: str, program: Path, map_file: Path, testpgms_bin: Path, testpgms_txt: Path, testpgms_zip: Path, version: str) -> None:
    stage_dir = zip_out.parent / stage_name
    ensure_clean_dir(stage_dir)
    prepare_dm_base(stage_dir, testpgms_bin, testpgms_txt, testpgms_zip)
    copy_file(program, stage_dir / program.name)
    copy_file(UPSTREAM_SOURCE_ROOT / "res/keymaps/keymap_R47.bin", stage_dir / "resources/keymap_R47.bin")
    copy_file(UPSTREAM_SOURCE_ROOT / "res/dmcp5/SwissMicros/DM42_qspi_3.x.bin", stage_dir / "resources/DM42_qspi_3.x.bin")
    zip_file(stage_dir / "resources/R47.map.zip", map_file, map_file.name)
    copy_file(UPSTREAM_SOURCE_ROOT / "res/dmcp5/install_R47_on_DM32.txt", stage_dir / "resources/install_R47_on_DM32.txt")
    copy_file(UPSTREAM_SOURCE_ROOT / "res/dmcp5/update_R47.txt", stage_dir / "update_R47.txt")
    copy_file(UPSTREAM_SOURCE_ROOT / "res/combo/R47_combo.py", stage_dir / "R47_combo.py")
    copy_file(UPSTREAM_SOURCE_ROOT / "res/combo/DMCP5_flash_3.56.bin", stage_dir / "DMCP5_flash_3.56.bin")
    run_command([sys.executable, "R47_combo.py", version], cwd=stage_dir)
    (stage_dir / "R47_combo.py").unlink(missing_ok=True)
    (stage_dir / "DMCP5_flash_3.56.bin").unlink(missing_ok=True)
    zip_tree(zip_out, stage_dir, stage_name)
    shutil.rmtree(stage_dir)


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        fail("usage: zig_dist.py <command> [args...]")

    command = argv[1]

    if command == "clone-wiki":
        clone_wiki(Path(argv[2]))
        return 0

    if command == "make-testpgms":
        make_testpgms_zip(Path(argv[2]), Path(argv[3]), Path(argv[4]), Path(argv[5]))
        return 0

    if command == "package-host":
        flavor = argv[2]
        wiki_dir = Path(argv[10]) if len(argv) > 10 else None
        package_host(flavor, Path(argv[3]), argv[4], Path(argv[5]), Path(argv[6]), Path(argv[7]), Path(argv[8]), Path(argv[9]), wiki_dir)
        return 0

    if command == "package-dmcp":
        wiki_dir = Path(argv[10]) if len(argv) > 11 else None
        include_packages = argv[11] == "with-packages" if wiki_dir is not None else argv[10] == "with-packages"
        package_dmcp(Path(argv[2]), argv[3], Path(argv[4]), Path(argv[5]), Path(argv[6]), Path(argv[7]), Path(argv[8]), Path(argv[9]), wiki_dir, include_packages)
        return 0

    if command == "package-dmcpr47":
        wiki_dir = Path(argv[10]) if len(argv) > 10 else None
        package_dmcpr47(Path(argv[2]), argv[3], Path(argv[4]), Path(argv[5]), Path(argv[6]), Path(argv[7]), Path(argv[8]), Path(argv[9]), wiki_dir)
        return 0

    if command == "package-dmcp5":
        package_dmcp5(Path(argv[2]), argv[3], Path(argv[4]), Path(argv[5]), Path(argv[6]), Path(argv[7]), Path(argv[8]))
        return 0

    if command == "package-dmcp5r47":
        package_dmcp5r47(Path(argv[2]), argv[3], Path(argv[4]), Path(argv[5]), Path(argv[6]), Path(argv[7]), Path(argv[8]), argv[9])
        return 0

    fail(f"unknown command: {command}")


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv))
    except subprocess.CalledProcessError as exc:
        raise SystemExit(exc.returncode) from exc