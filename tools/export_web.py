#!/usr/bin/env python3
"""Build the release Web preset and package its files for itch.io."""
import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--godot", default=shutil.which("godot") or "/Applications/Godot.app/Contents/MacOS/Godot")
parser.add_argument("--templates", type=Path, help="Official Godot 4.7.2 export_templates.tpz archive")
args = parser.parse_args()
version = subprocess.check_output([args.godot, "--version"], text=True).strip()
if not version.startswith("4.7.2.stable"):
    parser.error(f"Expected Godot 4.7.2 stable, got {version}")
exports = ROOT / "exports"
templates = exports / "templates"
templates.mkdir(parents=True, exist_ok=True)
(exports / ".gdignore").touch()
if args.templates:
    with zipfile.ZipFile(args.templates) as archive:
        if archive.read("templates/version.txt").decode().strip() != "4.7.2.stable":
            parser.error("The template archive must match Godot 4.7.2 stable")
        for name in ("web_nothreads_debug.zip", "web_nothreads_release.zip"):
            (templates / name).write_bytes(archive.read("templates/" + name))
if not (templates / "web_nothreads_release.zip").is_file():
    parser.error("Missing Web templates. Pass --templates /path/to/Godot_v4.7.2-stable_export_templates.tpz")

# Import first so a clean checkout includes every dynamically loaded SVG icon.
subprocess.run([args.godot, "--headless", "--path", str(ROOT), "--import"], check=True)
with tempfile.TemporaryDirectory(prefix="web-build-", dir=exports) as temporary:
    stage = Path(temporary)
    subprocess.run([args.godot, "--headless", "--path", str(ROOT), "--export-release", "Web (itch.io)", str(stage / "index.html")], check=True)
    files = sorted(p for p in stage.iterdir() if p.is_file())
    required = {"index.html", "index.js", "index.wasm", "index.pck"}
    if not required.issubset({p.name for p in files}):
        raise RuntimeError("Incomplete Web export")
    if len(files) > 1000 or sum(p.stat().st_size for p in files) > 500_000_000 or any(p.stat().st_size > 200_000_000 for p in files):
        raise RuntimeError("Export exceeds itch.io HTML5 archive limits")
    package = exports / "fieldwork-v5-web-itch.zip"
    with zipfile.ZipFile(package, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for file in files:
            archive.write(file, file.name)
    # Keep the same files available for local HTTP preview.
    preview = exports / "web"
    preview.mkdir(exist_ok=True)
    for file in files:
        shutil.copy2(file, preview / file.name)
print(f"Ready: {package} ({package.stat().st_size / 1_000_000:.1f} MB)")
print(f"Preview: python3 -m http.server 8065 --bind 127.0.0.1 --directory {preview}")
