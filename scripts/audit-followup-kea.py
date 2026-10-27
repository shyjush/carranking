#!/usr/bin/env python3
"""Read-only full-catalog reconciliation; no replay counted as a write."""
import gzip,hashlib,importlib.util,json,pathlib,sys
from decimal import Decimal
R=pathlib.Path('research/followup-20261027')
raw=pathlib.Path(sys.argv[1]) if len(sys.argv)>1 else pathlib.Path('../work/source/kea-all-pages-staging.json')
data=json.loads(raw.read_text());assert len(data['items'])==data['totalCount']==3732
s=importlib.util.spec_from_file_location('variants','scripts/kea-verified-variants.py');v=importlib.util.module_from_spec(s);s.loader.exec_module(v)
def read(n):
 p=R/('before-'+n+'.json')
 return json.loads(p.read_text() if p.exists() else gzip.decompress(pathlib.Path(str(p)+'.gz').read_bytes()))
rows,summary=v.plan(data,*[read(n) for n in ['manufacturers','models','generations']])
old={x['id']:x for x in read('specs')};same=[];different=[];new=[]
for r in rows:
 x=old.get(r['spec_id'])
 if not x:new.append(r['source_key'])
 elif x['powertrain_id']==r['powertrain_id'] and x['combined_efficiency']==r['efficiency']:same.append(r['source_key'])
 else:different.append(r['source_key'])
catalog=read('kea-catalog');official={}
for r in data['items']:
 if r.get('CAR_KIND')!='승용차':continue
 try:
  maker=r['COMP_NM'].strip();model=r['MODEL_NM'].strip();year=int(r['YEAR']);fuel=r['FUEL_NM'].strip();cc=None if fuel=='전기' else int(r['ENGINE_DISPLACEMENT']);eff=Decimal(str(r['DISPLAY_EFF']))
  key=hashlib.sha256('\x1f'.join([maker,model,str(year),fuel,str(cc),str(eff)]).encode()).hexdigest()
  official[key]=(maker,model,year,fuel,cc,float(eff))
 except (KeyError,TypeError,ValueError):continue
unchanged=0;conflicts=[]
for r in catalog:
 expected=(r['manufacturer'],r['model_detail'],r['certification_year'],r['official_fuel_name'],r['displacement_cc'],float(r['combined_efficiency']))
 if official.get(r['source_key'])==expected:unchanged+=1
 else:conflicts.append(r['source_key'])
out={'source_file_sha256':hashlib.sha256(raw.read_bytes()).hexdigest(),'source_origin':'2026-10-27 successful complete API run, retained staging; reused without re-triggering Actions','received':3732,'catalog_reviewed':len(catalog),'catalog_unchanged':unchanged,'catalog_conflicts':conflicts,'explicit_generation_passed':len(rows),'existing_variant_unchanged':len(same),'new_explicit_variants':new,'existing_variant_conflicts':different,'source_rules':summary,'writes':0}
assert not new and not different and not conflicts and unchanged==3185
(R/'kea-reconciliation.json').write_text(json.dumps(out,ensure_ascii=False,indent=2));print(json.dumps(out,ensure_ascii=False))
