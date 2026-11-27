"""Publish the final protected check (at ba33e33) into campaign/post with the same sanitization rule; append to SANITIZATION.json."""
import hashlib, json, os, importlib.util
here = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location('pc', os.path.join(here, 'publish_campaign.py'))
src = open(os.path.join(here, 'publish_campaign.py'), encoding='utf-8').read()
ns = {}
exec(src.split('sha = lambda')[0], ns)   # PAT, variants, sanitize only (no publishing side effects)
f = os.path.join(here, 'post', 'LP2B1EQ_PROTECTED_FINAL_ba33e33.json')
b = open(f, 'rb').read(); t, n = ns['sanitize'](b.decode('utf-8').replace('\r\n', '\n')); ob = t.encode('utf-8')
dst = os.path.join(ns['DST'], 'post', os.path.basename(f)); assert not os.path.exists(dst); open(dst, 'wb').write(ob)
sp = os.path.join(ns['DST'], 'post', 'SANITIZATION.json'); S = json.load(open(sp, encoding='utf-8'))
S['files'].append({'file': os.path.basename(f), 'sourceSHA256': hashlib.sha256(b).hexdigest(), 'publishedSHA256': hashlib.sha256(ob).hexdigest(), 'replacements': n})
json.dump(S, open(sp, 'w', encoding='utf-8', newline='\n'), indent=1)
print('published', dst, n)
