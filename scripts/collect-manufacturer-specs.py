#!/usr/bin/env python3
"""One-time read-only collection. Keep source hashes and structured facts, not page copies."""
import concurrent.futures, hashlib, html, json, pathlib, re, urllib.request
OUT=pathlib.Path('research/followup-20261027')
def plain(s):
 return re.sub(r'\s+',' ',html.unescape(re.sub('<[^>]+>',' ',s))).strip()
def collect(model):
 url=f'https://www.kia.com/kr/vehicles/{model}/specification'
 data=urllib.request.urlopen(url,timeout=45).read(); text=data.decode()
 rows=[]
 for block in re.split(r'<div class="cmp-container__row-wrap">',text)[1:]:
  block=block.split('<div class="cmp-container__row-wrap">')[0]
  ps=[plain(x) for x in re.findall(r'<p class="item_(?:tit|inform)">(.*?)</p>',block,re.S)]
  if len(ps)>=6 and any('복합' in x for x in ps): rows.append([x for x in ps if x][:8])
 # Electric pages use the same item structure, retained for review.
 return model,{'url':url,'sha256':hashlib.sha256(data).hexdigest(),'checked_at':'2026-10-27','rows':rows}
if __name__=='__main__':
 with concurrent.futures.ThreadPoolExecutor(max_workers=5) as pool:
  facts=dict(pool.map(collect,['ev3','ev4','ev5','ev6','ev9','ray','sportage','sorento','carnival']))
 (OUT/'manufacturer-facts.json').write_text(json.dumps(facts,ensure_ascii=False,indent=2))
 print(json.dumps(facts,ensure_ascii=False,indent=2))
