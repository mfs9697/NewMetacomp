"""Restore exact committed figure bytes, without checkout or computation."""
import argparse
import csv
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
REPO = Path(subprocess.check_output(
    ["git", "-C", str(ROOT), "rev-parse", "--show-toplevel"],
    text=True).strip())
CATALOG = ROOT / "evidence" / "SR0_FIGURE_CATALOG.csv"
OUT = ROOT / "build" / "figure_archive"

def git(*args):
    return subprocess.check_output(["git", "-C", str(REPO), *args])

def ensure_commit(sha):
    if subprocess.run(["git", "-C", str(REPO), "cat-file", "-e",
                       sha + "^{commit}"], stdout=subprocess.DEVNULL,
                      stderr=subprocess.DEVNULL).returncode:
        subprocess.run(["git", "-C", str(REPO), "fetch", "--no-tags",
                        "origin", sha], check=True)
    git("cat-file", "-e", sha + "^{commit}")

def restore(row, known):
    sha, blob, source = (row["pinned_commit"], row["git_blob_sha1"],
                         row["source_path"])
    if not all(re.fullmatch(r"[0-9a-f]{40}", x) for x in (sha, blob)):
        raise ValueError("Invalid Git SHA")
    rel = Path(source)
    if rel.is_absolute() or ".." in rel.parts:
        raise ValueError("Unsafe relative path")
    if sha not in known:
        ensure_commit(sha)
        known.add(sha)
    data = git("show", sha + ":" + source)
    actual = hashlib.sha1(b"blob " + str(len(data)).encode("ascii")
                          + b"\0" + data).hexdigest()
    if actual != blob or (row["bytes"] and len(data) != int(row["bytes"])):
        raise ValueError("Source blob/size mismatch: " + source)
    dest = (OUT / rel).resolve()
    dest.relative_to(OUT.resolve())
    if dest.exists() and dest.read_bytes() != data:
        raise ValueError("Refusing to overwrite different local file: " + str(dest))
    dest.parent.mkdir(parents=True, exist_ok=True)
    if not dest.exists():
        dest.write_bytes(data)
    return {"path": source, "commit": sha, "blob": blob,
            "sha256": hashlib.sha256(data).hexdigest(), "bytes": len(data)}

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--all", action="store_true",
                    help="Include documents and layout-check files")
    ap.add_argument("--match", default=".", help="Regex on source path")
    args = ap.parse_args()
    matcher = re.compile(args.match, re.IGNORECASE)
    with CATALOG.open(encoding="utf-8", newline="") as f:
        rows = [row for row in csv.DictReader(f)
                if matcher.search(row["source_path"])
                and (args.all or row["provisional_type"] in
                     ("FIGURE_CANDIDATE", "REVIEW_NEEDED"))]
    if not rows:
        ap.error("No matching catalog records")
    known, done = set(), []
    for row in rows:
        done.append(restore(row, known))
    OUT.mkdir(parents=True, exist_ok=True)
    manifest = OUT / "RESTORED_MANIFEST.json"
    manifest.write_text(json.dumps(done, ensure_ascii=False, indent=2)
                        + "\n", encoding="utf-8")
    print(f"Verified {len(done)} files. Manifest: {manifest}")

if __name__ == "__main__":
    main()
