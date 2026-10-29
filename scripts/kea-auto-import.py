#!/usr/bin/env python3
"""INSERT-only exact-generation certified variants; no AI or broad year matching."""
import importlib.util,json,os,pathlib,re,subprocess
root=pathlib.Path('official-economy-reports');root.mkdir(exist_ok=True)
report={'status':'not configured','scanned':0,'matched':0,'inserted':0,'updated':0,'unchanged':0,'new_models':0,'new_generations':0,'errors':0}
def finish():
 (root/'kea-auto-import.json').write_text(json.dumps(report,ensure_ascii=False,indent=2))
 print(json.dumps(report,ensure_ascii=False))
stage=root/'kea-all-pages-staging.json'
if not stage.exists():finish();raise SystemExit(0)
if not os.getenv('PGPASSWORD'):raise SystemExit('Missing database secret')
conn='host=aws-0-ap-northeast-2.pooler.supabase.com port=5432 dbname=postgres user=postgres.ikhyadzboorscjwcrhcz sslmode=require'
def query(sql):
 p=subprocess.run(['psql',conn,'-X','-v','ON_ERROR_STOP=1','-At'],input=sql,capture_output=True,text=True,timeout=180)
 if p.returncode:raise RuntimeError('Database query rejected')
 return p.stdout
module=importlib.util.spec_from_file_location('verified',pathlib.Path(__file__).with_name('kea-verified-variants.py'))
verified=importlib.util.module_from_spec(module);module.loader.exec_module(verified)
db=json.loads(query("select jsonb_build_object('manufacturers',(select jsonb_agg(x) from public.manufacturers x),'models',(select jsonb_agg(x) from public.car_models x),'generations',(select jsonb_agg(x) from public.generations x));"))
rows,summary=verified.plan(json.loads(stage.read_text()),db['manufacturers'],db['models'],db['generations'])
(root/'kea-variant-plan.json').write_text(json.dumps({'summary':summary,'approved':rows},ensure_ascii=False,indent=2))
# Discover missing official model names separately; never auto-publish inferred generations.
# Only manufacturer-supported KEA rows with a safe model-name prefix are candidates.
import collections
known={x['name'].strip().casefold() for x in db['models']}
aliases={'현대':'현대','기아':'기아','제네시스':'현대'}
maker_names={x['id']:x['name'] for x in db['manufacturers']}
known_by_maker={(aliases.get(maker_names[m['manufacturer_id']],maker_names[m['manufacturer_id']]),m['name'].strip().casefold()) for m in db['models']}
candidates=collections.defaultdict(lambda:{'records':0,'years':set(),'examples':set()})
for item in json.loads(stage.read_text())['items']:
 if item.get('CAR_KIND')!='승용차':continue
 maker=str(item.get('COMP_NM') or '').strip()
 label=str(item.get('MODEL_NM') or '').strip()
 # Extract only names followed by an explicit factory generation code in parentheses.
 hit=re.match(r'^([가-힣A-Za-z0-9][가-힣A-Za-z0-9 -]{1,45}?)\s*\(([A-Za-z][A-Za-z0-9 -]{1,12})\)',label)
 if not hit or maker not in ('현대','기아'):continue
 model=hit.group(1).strip()
 if (maker,model.casefold()) in known_by_maker:continue
 key=(maker,model)
 c=candidates[key];c['records']+=1;c['years'].add(str(item.get('YEAR','')));c['examples'].add(label)
discovered=[{'manufacturer':maker,'model_candidate':model,'source':'KEA','records':c['records'],'certification_years':sorted(c['years']),'examples':sorted(c['examples'])[:3],'status':'review_required_not_published'} for (maker,model),c in sorted(candidates.items())]
(root/'kea-new-model-candidates.json').write_text(json.dumps({'count':len(discovered),'candidates':discovered},ensure_ascii=False,indent=2))
report['new_model_candidates']=len(discovered)

report.update(scanned=summary['collected'],matched=summary['validated'],duplicates=summary['duplicates'],held=summary['held'],reasons=summary['reasons'])
output=query(verified.sql(rows))
counts=dict((kind,int(n)) for kind,n in re.findall(r'^(powertrains|specs)\|(\d+)$',output,re.M))
if rows and set(counts)!= {'powertrains','specs'}:raise RuntimeError('Missing actual INSERT counts')
report.update(inserted=counts.get('specs',0),powertrains_inserted=counts.get('powertrains',0),unchanged=len(rows)-counts.get('specs',0),status='complete')
finish()
