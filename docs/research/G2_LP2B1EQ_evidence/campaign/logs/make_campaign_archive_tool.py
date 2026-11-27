import sys
src, dst = sys.argv[1], sys.argv[2]
t = open(src, 'rb').read().decode('utf-8').replace('\r\n', '\n')
t = t.replace('"""Build and verify the LP2-B1-EQ readiness archive',
              '"""Build and verify the LP2-B1-EQ CAMPAIGN archive (variant of lp2b1eq_archive.py: <outputsRels> is a comma-separated list\nof folders and/or single files relative to the clone)', 1)
t = t.replace('usage: python lp2b1eq_archive.py <execRepo> <outputsRel>', 'usage: python lp2b1eq_campaign_archive.py <execRepo> <outputsRels>', 1)
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
t = t.replace(old, new).replace('date_time=(2026, 11, 26, 0, 0, 0)', 'date_time=(2026, 11, 27, 0, 0, 0)')
open(dst, 'w', encoding='utf-8', newline='\n').write(t)
print('ok')
