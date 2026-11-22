"""Verify LP1 evidence; optionally restore missing, SHA-verified outputs only."""
from pathlib import Path
import argparse
import hashlib
import json
import shutil
import zipfile


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--historical-root', action='append', type=Path, default=[])
    parser.add_argument('--raw-archive', type=Path)
    parser.add_argument('--restore', action='store_true')
    args = parser.parse_args()
    repo = Path(__file__).resolve().parents[2]
    outputs = (repo / 'outputs').resolve()
    lock = json.loads((repo / 'matlab/g2/G2_LP0_SOURCE_LOCK_v1.json').read_text())
    evidence = repo / 'matlab/g2/evidence/lp1_20261122'
    raw = json.loads((evidence / 'RAW_RECORDS_SHA256.json').read_text())
    archive_meta = json.loads((evidence / 'FINAL_PRESERVATION_CHECK.json').read_text())
    missing = []
    restored = 0
    for entry in lock['legacy']:
        target = repo / entry['file']
        if not target.is_file() or digest(target) != entry['sha256']:
            raise RuntimeError('Historical source mismatch: ' + entry['file'])
    # Plan and validate all historical copies before creating any destination.
    copies = []
    for entry in lock['acceptedInputs']:
        target = (repo / entry['file']).resolve()
        target.relative_to(outputs)
        if target.exists():
            if digest(target) != entry['sha256']:
                raise RuntimeError('Refuse changed accepted MAT: ' + str(target))
        else:
            source = next((r / entry['file'] for r in args.historical_root
                           if (r / entry['file']).is_file()
                           and digest(r / entry['file']) == entry['sha256']), None)
            if args.restore and source is not None:
                copies.append((source, target, entry['sha256']))
            else:
                missing.append(entry['file'])
    run = outputs / 'g2_lp1_matrix_paths_v1/run_20261122_lp1_v1'
    to_extract = []
    for name, expected in raw.items():
        target = (run / name).resolve()
        target.relative_to(run.resolve())
        if target.exists():
            if digest(target) != expected:
                raise RuntimeError('Refuse changed campaign record: ' + name)
        else:
            to_extract.append((name, target, expected))
    archive = None
    try:
        if to_extract and args.restore and args.raw_archive:
            if digest(args.raw_archive) != archive_meta['rawArchiveSHA256']:
                raise RuntimeError('Raw archive SHA mismatch')
            archive = zipfile.ZipFile(args.raw_archive)
            names = [n for n in archive.namelist() if not n.endswith('/')]
            if len(names) != len(set(names)) or set(names) != set(raw):
                raise RuntimeError('Raw archive member set mismatch')
            for name in names:
                if hashlib.sha256(archive.read(name)).hexdigest() != raw[name]:
                    raise RuntimeError('Raw archive member mismatch: ' + name)
        elif to_extract:
            missing.extend('campaign/' + n for n, _, _ in to_extract)
        if missing:
            raise RuntimeError('HOLD_INPUT: missing verified inputs: ' + ', '.join(missing))
        for source, target, expected in copies:
            target.parent.mkdir(parents=True, exist_ok=True)
            with source.open('rb') as src, target.open('xb') as dst:
                shutil.copyfileobj(src, dst)
            assert digest(target) == expected
            restored += 1
        if archive:
            for name, target, expected in to_extract:
                target.parent.mkdir(parents=True, exist_ok=True)
                with target.open('xb') as stream:
                    stream.write(archive.read(name))
                assert digest(target) == expected
                restored += 1
    finally:
        if archive:
            archive.close()
    print(json.dumps({'pass': True, 'legacy': len(lock['legacy']),
                      'historicalMAT': len(lock['acceptedInputs']),
                      'campaignFiles': len(raw), 'restored': restored}))


if __name__ == '__main__':
    main()
