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
 p=subprocess.run(['psql',conn,'-X','-v','ON_ERROR_STOP=1','-At'],input=sql,capture_output=True,text=True,timeout=100)
 if p.returncode:raise RuntimeError('Database query rejected')
 return p.stdout
module=importlib.util.spec_from_file_location('verified',pathlib.Path(__file__).with_name('kea-verified-variants.py'))
verified=importlib.util.module_from_spec(module);module.loader.exec_module(verified)
db=json.loads(query("select jsonb_build_object('manufacturers',(select jsonb_agg(x) from public.manufacturers x),'models',(select jsonb_agg(x) from public.car_models x),'generations',(select jsonb_agg(x) from public.generations x));"))
rows,summary=verified.plan(json.loads(stage.read_text()),db['manufacturers'],db['models'],db['generations'])
(root/'kea-variant-plan.json').write_text(json.dumps({'summary':summary,'approved':rows},ensure_ascii=False,indent=2))
report.update(scanned=summary['collected'],matched=summary['validated'],duplicates=summary['duplicates'],held=summary['held'],reasons=summary['reasons'])
output=query(verified.sql(rows))
counts=dict((kind,int(n)) for kind,n in re.findall(r'^(powertrains|specs)\|(\d+)$',output,re.M))
if rows and set(counts)!= {'powertrains','specs'}:raise RuntimeError('Missing actual INSERT counts')
report.update(inserted=counts.get('specs',0),powertrains_inserted=counts.get('powertrains',0),unchanged=len(rows)-counts.get('specs',0),status='complete')
finish()
