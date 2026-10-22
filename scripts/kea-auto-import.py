#!/usr/bin/env python3
"""Auto-import exact uniquely matched KEA official efficiency data, never guess trims.
Reads the fetched public energy data staged by official-api-sync.py. No credentials in artifacts.
"""
import csv, datetime as dt, json, os, pathlib, re, subprocess, unicodedata
from urllib.parse import urlparse
root=pathlib.Path('official-economy-reports');root.mkdir(exist_ok=True)
stage=root/'kea-all-pages-staging.json'
report={'mode':'strict automatic KEA official match','scanned':0,'matched':0,'inserted':0,'ambiguous':0,'unmatched':0,'status':'not configured'}
def finish():
 (root/'kea-auto-import.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
 print(json.dumps(report,ensure_ascii=False))
if not stage.exists():
 finish();raise SystemExit(0)
def normalize(s):return re.sub(r'[^0-9a-z가-힣]','',unicodedata.normalize('NFKC',str(s or '')).lower())
def get(row,*names):
 for n in names:
  for k,v in row.items():
   if normalize(k)==normalize(n) and v is not None and str(v).strip():return str(v).strip()
 return ''
def recurse(x):
 if isinstance(x,list):
  for v in x:yield from recurse(v)
 elif isinstance(x,dict):
  if any(normalize(k) in ('modelnm','modelname','차명','모델명','차종명') for k in x):yield x
  else:
   for k,v in x.items():yield from recurse(v)
def fuel(s):
 s=normalize(s)
 if any(x in s for x in ('전기','electric','ev')):return 'ev'
 if any(x in s for x in ('경유','디젤','diesel')):return 'diesel'
 if 'lpg' in s:return 'lpg'
 if any(x in s for x in ('가솔린','휘발유','gasoline','하이브리드','hybrid')):return 'gas'
 return ''
def sql_quote(v):return "'"+str(v).replace("'","''")+"'"
def query(sql):
 conn='host=aws-0-ap-northeast-2.pooler.supabase.com port=5432 dbname=postgres user=postgres.ikhyadzboorscjwcrhcz sslmode=require'
 p=subprocess.run(['psql',conn,'-X','-v','ON_ERROR_STOP=1','--csv','-c',sql],capture_output=True,text=True)
 if p.returncode:raise RuntimeError('Database query failed: '+p.stderr[-350:])
 return list(csv.DictReader(p.stdout.splitlines()))
if not os.getenv('PGPASSWORD'):raise SystemExit('Missing database secret')
db=query("""select p.id as powertrain_id,p.generation_id,d.brand,d.model,coalesce(d.generation_code,'') as generation_code,p.name as powertrain,p.fuel_type,coalesce(p.displacement_cc::text,'') as cc from public.powertrains p join public.web_vehicle_detail d on d.generation_id=p.generation_id where not exists(select 1 from public.vehicle_specs s where s.powertrain_id=p.id and coalesce(s.combined_efficiency,'')<>'')""")
staged=json.loads(stage.read_text(encoding='utf8'))
records=staged.get('items',[]) if isinstance(staged,dict) else []
if not isinstance(records,list):raise RuntimeError('KEA staged items must be a list')
report['scanned']=len(records)
matches={}
for row in records:
 model=get(row,'MODEL_NM','modelNm','modelName','모델명','차명','차종명')
 maker=get(row,'COMP_NM','makerNm','companyNm','manufacturer','제조사','업체명')
 combined=get(row,'DISPLAY_EFF','combEff','combinedEfficiency','combinedFuelEfficiency','복합연비','복합전비','연비')
 cc=get(row,'ENGINE_DISPLACEMENT','displacement','배기량','engineSize','배기량(cc)')
 variant=get(row,'MODEL_NM','trimName','차량세부명','세부모델명','차종상세명','modelDetail')
 year=get(row,'YEAR','year','연식','modelYear','모델연도')
 energy=fuel(get(row,'FUEL_NM','fuelType','fuelNm','연료','유종'))
 matchnumber=re.search(r'\d+(?:\.\d+)?',combined.replace(',',''))
 if not maker or not model or not matchnumber or not energy or not variant or not year:
  report['unmatched']+=1;continue
 value=float(matchnumber.group())
 if not 0.5<=value<=40:report['unmatched']+=1;continue
 possible=[]
 for p in db:
  brand=normalize(p['brand']);official=normalize(maker);name=normalize(model)
  brand_ok=(brand==official or (brand=='기아' and ('기아' in official or 'kia' in official)) or (brand=='현대' and ('현대' in official or 'hyundai' in official)) or (brand=='제네시스' and ('현대' in official or '제네시스' in official or 'genesis' in official)))
  if not brand_ok or not name.startswith(normalize(p['model'])):continue
  if fuel(p['fuel_type'])!=energy:continue
  if energy!='ev' and (not cc.isdigit() or abs(int(cc)-int(p['cc'] or 0))>3):continue
  # Exact registered powertrain label must appear in official variant, not a broad model-only match.
  label=normalize(p['powertrain'])
  # Every drive or drivetrain trait registered in DB must be explicitly supported by the official name.
  drive=re.search(r'(2wd|4wd|awd)',label)
  if drive and drive.group(1) not in normalize(variant):continue
  possible.append(p)
 if len(possible)!=1:report['ambiguous' if possible else 'unmatched']+=1;continue
 p=possible[0]
 # Multiple official trims for one powertrain differ by wheel/drive/option; never arbitrarily pick one.
 matches.setdefault(p['powertrain_id'],[]).append((p,row,value,energy,variant,year))
approved=[v[0] for v in matches.values() if len(v)==1]
report['matched']=len(approved);report['ambiguous']+=sum(len(v) for v in matches.values() if len(v)>1)
if approved:
 entries=[]
 for p,row,value,energy,variant,year in approved:
  unit='km/kWh' if energy=='ev' else 'km/L'
  label=f'{value:g} {unit} (공식 API {variant[:100]}, {year[:20]}년식)'
  entries.append('('+','.join(map(sql_quote,[p['generation_id'],p['powertrain_id'],label]))+')')
 values=','.join(entries)
 url='https://www.data.go.kr/data/15139827/openapi.do'
 cmd=f"""begin;
 create temporary table kea_verified_import(generation_id uuid,powertrain_id uuid,eff text);
 insert into kea_verified_import values {values};
 insert into public.vehicle_specs(generation_id,powertrain_id,combined_efficiency,source_url,verified_at)
 select q.generation_id,q.powertrain_id,q.eff,{sql_quote(url)},current_date
 from kea_verified_import q
 join public.powertrains p on p.id=q.powertrain_id and p.generation_id=q.generation_id
 where not exists(select 1 from public.vehicle_specs s where s.powertrain_id=q.powertrain_id and coalesce(s.combined_efficiency,'')<>'')
 and not exists(select 1 from public.vehicle_specs s where s.powertrain_id=q.powertrain_id);
 commit;"""
 conn='host=aws-0-ap-northeast-2.pooler.supabase.com port=5432 dbname=postgres user=postgres.ikhyadzboorscjwcrhcz sslmode=require'
 run=subprocess.run(['psql',conn,'-X','-v','ON_ERROR_STOP=1','-c',cmd],capture_output=True,text=True)
 if run.returncode:raise RuntimeError('Safe import rejected: '+run.stderr[-400:])
 nums=re.findall(r'INSERT 0 (\d+)',run.stdout)
 report['inserted']=int(nums[-1]) if nums else 0
report['status']='complete'
finish()
