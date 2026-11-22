"""SR1 independent check of the LP1 raw-record archive against the committed ledger.

Read-only with respect to the repository: reads the archive, compares its SHA-256
with FINAL_PRESERVATION_CHECK.json and every member with RAW_RECORDS_SHA256.json.
With --extract DIR (a new, empty directory outside the repository) the verified
members are also written there for inspection.

  python -I scripts/g2/sr1/sr1_verify_archive.py ARCHIVE.zip [--extract DIR]
"""
import argparse
import hashlib
import json
import zipfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
EV = REPO / 'matlab' / 'g2' / 'evidence' / 'lp1_20261122'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('archive', type=Path)
    ap.add_argument('--extract', type=Path)
    a = ap.parse_args()
    meta = json.loads((EV / 'FINAL_PRESERVATION_CHECK.json').read_text(encoding='utf-8'))
    ledger = json.loads((EV / 'RAW_RECORDS_SHA256.json').read_text(encoding='utf-8'))
    data = a.archive.read_bytes()
    sha = hashlib.sha256(data).hexdigest()
    out = {'archiveBytes': len(data), 'archiveSHA256': sha,
           'archiveMatchesCommitted': sha == meta['rawArchiveSHA256'] and len(data) == meta['rawArchiveBytes']}
    z = zipfile.ZipFile(a.archive)
    names = [n for n in z.namelist() if not n.endswith('/')]
    ok = [n for n in names if n in ledger and hashlib.sha256(z.read(n)).hexdigest() == ledger[n]]
    out.update({'members': len(names), 'ledgerEntries': len(ledger), 'membersMatching': len(ok),
                'duplicateNames': len(names) - len(set(names)),
                'missingFromArchive': sorted(set(ledger) - set(names)),
                'notInLedger': sorted(set(names) - set(ledger))})
    out['pass'] = (out['archiveMatchesCommitted'] and len(ok) == len(ledger) == len(names)
                   and not out['duplicateNames'])
    if a.extract and out['pass']:
        a.extract.mkdir(parents=True, exist_ok=False)
        for n in names:
            dst = (a.extract / n).resolve()
            dst.relative_to(a.extract.resolve())
            dst.parent.mkdir(parents=True, exist_ok=True)
            dst.write_bytes(z.read(n))
    print(json.dumps(out, indent=1))


if __name__ == '__main__':
    main()
