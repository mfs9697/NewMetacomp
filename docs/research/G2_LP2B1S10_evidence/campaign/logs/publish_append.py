"""Append late files to the published campaign evidence with the same sanitization rule; extend each folder's SANITIZATION.json.
usage: python -I publish_append.py <srcFile> <relDestination> [<srcFile> <relDestination> ...]"""
import hashlib, json, os, sys
here = os.path.dirname(os.path.abspath(__file__))
src = open(os.path.join(here, 'publish_campaign.py'), encoding='utf-8').read()
ns = {}
exec(src.split('sha = lambda')[0], ns)   # PAT, variants, sanitize, DST only (no publishing side effects)
args = sys.argv[1:]; assert args and len(args) % 2 == 0
for f, rel in zip(args[0::2], args[1::2]):
    b = open(f, 'rb').read()
    t = b.decode('utf-16') if b[:2] in (b'\xff\xfe', b'\xfe\xff') else b.decode('utf-8')
    t, n = ns['sanitize'](t.replace('\r\n', '\n'))
    if rel.endswith('.log'):
        t = '\n'.join(l for l in t.split('\n') if not l.startswith('[Warning: Name is nonexistent'))
    ob = t.encode('utf-8')
    dst = os.path.join(ns['DST'], *rel.split('/')); assert not os.path.exists(dst), dst
    os.makedirs(os.path.dirname(dst), exist_ok=True); open(dst, 'wb').write(ob)
    sp = os.path.join(os.path.dirname(dst), 'SANITIZATION.json'); S = json.load(open(sp, encoding='utf-8'))
    S['files'].append({'file': os.path.basename(rel), 'sourceSHA256': hashlib.sha256(b).hexdigest(), 'publishedSHA256': hashlib.sha256(ob).hexdigest(), 'replacements': n})
    json.dump(S, open(sp, 'w', encoding='utf-8', newline='\n'), indent=1)
    print('published', rel, n)
