"""Package and verify the same unsigned phone IPA in PR CI and releases."""

import argparse
from pathlib import Path
import plistlib
import shutil
import subprocess
import tempfile
import zipfile

parser = argparse.ArgumentParser()
parser.add_argument("archive", type=Path)
parser.add_argument("output", type=Path)
parser.add_argument("version")
parser.add_argument("build")
args = parser.parse_args()
app = args.archive / "Products/Applications/SwiftRadio.app"
info = plistlib.loads((app / "Info.plist").read_bytes())
expected = {"CFBundleIdentifier": "com.matthewfecher.SwiftRadio",
            "CFBundleShortVersionString": args.version, "CFBundleVersion": args.build}
for key, value in expected.items():
    if info.get(key) != value:
        raise SystemExit(f"Archive {key}: expected {value}, got {info.get(key)}")
binary = app / info["CFBundleExecutable"]
architectures = subprocess.check_output(["lipo", "-archs", str(binary)], text=True).split()
if architectures != ["arm64"]:
    raise SystemExit(f"Expected device arm64 binary, got {architectures}")
framework = app / "Frameworks/LNPopupUI.framework/LNPopupUI"
if not framework.is_file():
    raise SystemExit("Archive is missing the embedded LNPopupUI framework")
linkage = subprocess.check_output(["otool", "-L", str(binary)], text=True)
if "@rpath/LNPopupUI.framework/LNPopupUI" not in linkage:
    raise SystemExit("App does not link its embedded LNPopupUI framework")
output = args.output.resolve()
output.parent.mkdir(parents=True, exist_ok=True)
if output.exists():
    raise SystemExit(f"Refusing to replace existing package: {output}")
with tempfile.TemporaryDirectory(prefix="swiftradio-package-") as scratch:
    payload = Path(scratch) / "Payload"
    payload.mkdir()
    shutil.copytree(app, payload / app.name, symlinks=True)
    subprocess.run(["zip", "-qry", str(output), "Payload"], cwd=scratch, check=True)
with zipfile.ZipFile(output) as package:
    if package.testzip() is not None:
        raise SystemExit("IPA failed its ZIP integrity check")
    prefix = "Payload/SwiftRadio.app/"
    packaged_info = plistlib.loads(package.read(prefix + "Info.plist"))
    if any(packaged_info.get(key) != value for key, value in expected.items()):
        raise SystemExit("Packaged version differs from the archive")
    package.getinfo(prefix + "Frameworks/LNPopupUI.framework/LNPopupUI")
    package.getinfo(prefix + info["CFBundleExecutable"])
print(f"Verified unsigned device IPA: {output.name} ({args.version}, build {args.build})")
