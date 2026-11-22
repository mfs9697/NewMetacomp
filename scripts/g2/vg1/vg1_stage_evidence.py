"""Copy a batch/test output folder into committed VG1 evidence with path sanitization.

Every copied text file has local absolute paths replaced by <repo>, <scratch> or
<user>. SANITIZATION.json records, for every file, the SHA-256 of the ORIGINAL bytes
(which still match the run's own BATCH_MANIFEST.json) and of the sanitized copy.
Binary files are not copied. Read-only with respect to the source folder.

  python -I scripts/g2/vg1/vg1_stage_evidence.py SRC_DIR DEST_DIR --repo-root R [--extra-root PATH=TOKEN ...]
"""
import argparse
import hashlib
import json
from pathlib import Path


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('src', type=Path)
    ap.add_argument('dest', type=Path)
    ap.add_argument('--repo-root', required=True)
    ap.add_argument('--extra-root', action='append', default=[])
    a = ap.parse_args()
    a.dest.mkdir(parents=True, exist_ok=False)
    reps = [(a.repo_root, '<repo>')]
    for e in a.extra_root:
        p, t = e.rsplit('=', 1)
        reps.append((p, t))
    variants = []
    for p, t in reps:
        for v in {p, p.replace('/', '\\'), p.replace('\\', '/'), p.replace('\\', '\\\\'), p.replace('/', '\\\\')}:
            variants.append((v, t))
    variants.sort(key=lambda x: -len(x[0]))
    out = {'schema': 'NewMetacomp.G2.LP1.VG1.Sanitization.v1', 'source': a.src.name, 'files': []}
    for f in sorted(a.src.rglob('*')):
        if not f.is_file():
            continue
        raw = f.read_bytes()
        rel = f.relative_to(a.src).as_posix()
        if f.suffix.lower() in ('.mat',):
            out['files'].append({'file': rel, 'originalSHA256': hashlib.sha256(raw).hexdigest(), 'copied': False})
            continue
        if raw.startswith(b'\xff\xfe') or raw.startswith(b'\xfe\xff'):
            txt = raw.decode('utf-16')          # PowerShell 5.1 Tee-Object writes UTF-16
        else:
            txt = raw.decode('utf-8-sig', errors='replace')
        txt = txt.replace('\x00', '').replace('\r\n', '\n')
        for v, t in variants:
            txt = txt.replace(v, t)
        home = str(Path.home())
        txt = txt.replace(home, '<user>').replace(home.replace('\\', '/'), '<user>')
        dst = a.dest / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        dst.write_text(txt, encoding='utf-8', newline='\n')
        out['files'].append({'file': rel, 'originalSHA256': hashlib.sha256(raw).hexdigest(),
                             'sanitizedSHA256': hashlib.sha256(dst.read_bytes()).hexdigest(), 'copied': True})
    (a.dest / 'SANITIZATION.json').write_text(json.dumps(out, indent=1), encoding='utf-8', newline='\n')
    print(json.dumps({'files': len(out['files'])}))


if __name__ == '__main__':
    main()
