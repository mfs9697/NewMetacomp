"""Derive the LP2-B1-S10 CAMPAIGN archive tool from the accepted scripts/g2/lp2b1eq/lp2b1eq_archive.py, exactly as the accepted
LP2-B1-EQ campaign did: <outputsRels> becomes a comma-separated list of folders and/or single files; the fixed ZIP member time is
2026-11-28. Nothing else changes (deterministic ZIP, SHA-256 manifest, two copies, member-by-member re-verification, no overwrite).
usage: python -I make_archive_tool.py <lp2b1eq_archive.py> <out.py>"""
import sys
src, dst = sys.argv[1], sys.argv[2]
t = open(src, 'rb').read().decode('utf-8').replace('\r\n', '\n')
t = t.replace('"""Build and verify the LP2-B1-EQ readiness archive',
              '"""Build and verify the LP2-B1-S10 CAMPAIGN archive (variant of lp2b1eq_archive.py: <outputsRels> is a comma-separated list\nof folders and/or single files relative to the clone)', 1)
t = t.replace('usage: python lp2b1eq_archive.py <execRepo> <outputsRel>', 'usage: python lp2b1s10_campaign_archive.py <execRepo> <outputsRels>', 1)
old = ("members = []\n"
       "for d, _, fs in os.walk(os.path.join(ex, *orel.split('/'))):\n"
       "    for n in fs:\n"
       "        p = os.path.join(d, n); members.append((os.path.relpath(p, ex).replace('\\\\', '/'), p))\n")
new = ("members = []\n"
       "for rel in orel.split(','):\n"
       "    base = os.path.join(ex, *rel.split('/'))\n"
       "    if os.path.isfile(base):\n"
       "        members.append((rel, base)); continue\n"
       "    assert os.path.isdir(base), rel\n"
       "    for d, _, fs in os.walk(base):\n"
       "        for n in fs:\n"
       "            p = os.path.join(d, n); members.append((os.path.relpath(p, ex).replace('\\\\', '/'), p))\n")
assert t.count(old) == 1, 'pattern'
assert t.count('date_time=(2026, 11, 26, 0, 0, 0)') >= 1, 'date'
t = t.replace(old, new).replace('date_time=(2026, 11, 26, 0, 0, 0)', 'date_time=(2026, 11, 28, 0, 0, 0)')
open(dst, 'w', encoding='utf-8', newline='\n').write(t)
print('ok')
