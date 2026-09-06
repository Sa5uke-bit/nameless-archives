"""Package an already exported Windows game with player instructions and notices."""

import argparse
import hashlib
from pathlib import Path
import re
import zipfile


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", required=True)
    args = parser.parse_args()
    if not re.fullmatch(r"\d+\.\d+\.\d+", args.version):
        parser.error("Use a version such as 0.1.0")

    root = Path(__file__).resolve().parents[1]
    settings = (root / "project.godot").read_text(encoding="utf-8")
    if f'config/version="{args.version}"' not in settings:
        parser.error("Version must match project.godot; export the game before packaging")

    members = {
        "无名档案.exe": root / "builds/windows/无名档案.exe",
        "开始游戏.txt": root / "docs/releases/PLAYER_README.txt",
        "THIRD_PARTY_ASSETS.md": root / "docs/THIRD_PARTY_ASSETS.md",
        "licenses/GODOT_LICENSE.txt": root / "docs/licenses/GODOT_LICENSE.txt",
        "licenses/GODOT_COPYRIGHT.txt": root / "docs/licenses/GODOT_COPYRIGHT.txt",
    }
    for source in members.values():
        if not source.is_file():
            parser.error(f"Missing release input: {source}")

    output = root / "builds/releases" / f"v{args.version}"
    output.mkdir(parents=True, exist_ok=True)
    archive = output / f"nameless-archives-v{args.version}-windows-x86_64.zip"
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as bundle:
        for name, source in members.items():
            bundle.write(source, name)

    with zipfile.ZipFile(archive) as bundle:
        if bundle.testzip() is not None or set(bundle.namelist()) != set(members):
            raise RuntimeError("Release ZIP integrity check failed")
        if hashlib.sha256(bundle.read("无名档案.exe")).digest() != hashlib.sha256(
            members["无名档案.exe"].read_bytes()
        ).digest():
            raise RuntimeError("Packaged executable differs from the exported game")

    with archive.open("rb") as source:
        digest = hashlib.file_digest(source, "sha256").hexdigest()
    (output / "SHA256SUMS.txt").write_text(f"{digest}  {archive.name}\n", encoding="ascii")
    print(f"ZIP verified: {archive} ({archive.stat().st_size:,} bytes)")
    print(f"SHA-256: {digest}")


if __name__ == "__main__":
    main()
