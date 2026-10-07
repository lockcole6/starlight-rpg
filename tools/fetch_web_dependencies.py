"""Fetch official Godot Web templates and OFL fonts; standard-library only.

The large all-platform template archive is read with HTTP ranges. Only its Web
templates are downloaded, and zipfile verifies their CRC before saving them.
"""
from __future__ import annotations

import argparse
import io
import re
import urllib.request
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VERSION = "4.7"
TEMPLATE_URL = (
    f"https://github.com/godotengine/godot-builds/releases/download/{VERSION}-stable/"
    f"Godot_v{VERSION}-stable_export_templates.tpz"
)
HEADERS = {"User-Agent": "StarlightRPG-build/1.0"}


class RemoteZip(io.RawIOBase):
    def __init__(self, url: str):
        request = urllib.request.Request(url, headers={**HEADERS, "Range": "bytes=0-0"})
        with urllib.request.urlopen(request, timeout=90) as response:
            match = re.fullmatch(r"bytes 0-0/(\d+)", response.headers.get("Content-Range", ""))
            if response.status != 206 or not match:
                raise RuntimeError("Official download server did not honor the range request")
            self.size = int(match[1])
            self.url = response.geturl()
        self.position = 0

    def seekable(self):
        return True

    def readable(self):
        return True

    def tell(self):
        return self.position

    def seek(self, offset, whence=0):
        self.position = [offset, self.position + offset, self.size + offset][whence]
        return self.position

    def read(self, size=-1):
        if size < 0:
            size = self.size - self.position
        end = min(self.size, self.position + size) - 1
        if end < self.position:
            return b""
        expected = f"bytes {self.position}-{end}/{self.size}"
        request = urllib.request.Request(self.url, headers={
            **HEADERS, "Range": f"bytes={self.position}-{end}"
        })
        with urllib.request.urlopen(request, timeout=90) as response:
            if response.status != 206 or response.headers.get("Content-Range") != expected:
                raise RuntimeError("Unexpected byte range from template server")
            data = response.read()
        if len(data) != end - self.position + 1:
            raise RuntimeError("Truncated template download")
        self.position += len(data)
        return data


def templates():
    target = ROOT / ".tools" / "godot"
    target.mkdir(parents=True, exist_ok=True)
    (target.parent / ".gdignore").touch()
    if all(zipfile.is_zipfile(target / name) for name in (
        "web_nothreads_debug.zip", "web_nothreads_release.zip"
    )):
        print("Godot 4.7 Web templates are already available.", flush=True)
        return
    with zipfile.ZipFile(RemoteZip(TEMPLATE_URL)) as archive:
        candidates = [name for name in archive.namelist() if "/web" in name]
        print("Available Web templates:", candidates, flush=True)
        selected = [name for name in candidates if Path(name).name in (
            "web_nothreads_debug.zip", "web_nothreads_release.zip"
        )]
        if not selected:
            selected = [name for name in candidates if name.endswith(".zip")]
        for name in selected:
            path = target / Path(name).name
            if not path.exists():
                print("Downloading", name, flush=True)
                path.write_bytes(archive.read(name))
            print(path.relative_to(ROOT), path.stat().st_size, flush=True)


def fonts():
    entries = [
        ("mplus1p/MPLUS1p-Medium.ttf", "MPLUS1p-Medium.ttf"),
        ("mplus1p/OFL.txt", "MPLUS1p-OFL.txt"),
        ("shipporimincho/ShipporiMincho-SemiBold.ttf", "ShipporiMincho-SemiBold.ttf"),
        ("shipporimincho/OFL.txt", "ShipporiMincho-OFL.txt"),
    ]
    target = ROOT / "assets" / "fonts"
    target.mkdir(parents=True, exist_ok=True)
    for source, filename in entries:
        path = target / filename
        if not path.exists():
            url = "https://raw.githubusercontent.com/google/fonts/main/ofl/" + source
            with urllib.request.urlopen(urllib.request.Request(url, headers=HEADERS), timeout=90) as response:
                path.write_bytes(response.read())
        print(path.relative_to(ROOT), path.stat().st_size, flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fonts", action="store_true", help="Also download the bundled OFL fonts")
    args = parser.parse_args()
    templates()
    if args.fonts:
        fonts()
