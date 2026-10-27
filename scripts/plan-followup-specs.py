#!/usr/bin/env python3
"""Reviewed manufacturer facts -> deterministic, INSERT-only specification plan.
Does not infer model year from certification/observation dates or modify schedules.
"""
import collections,json,pathlib,re,uuid
ROOT=pathlib.Path('research/followup-20261027')
NS=uuid.UUID('5ca35648-a0dd-42f0-8394-04ed7115ac90')
def read(n):return json.loads((ROOT/n).read_text())
powers={p['id']:p for p in read('before-powertrains.json')}
facts=read('manufacturer-facts.json'); approved=[]
M={
 'ev3':{'2WD':'a8a953c7-cfab-4cb2-a254-d85e4298914e','4WD':'78b95b0b-85ba-44b6-b81a-3e0445b6c144'},
 'ev4':{'2WD':'207f7572-8619-427a-8934-b7ad6c12962d','4WD':'58e0cdb9-c714-4b62-891c-c20bdfee22aa','standard':'5d73717d-9a55-414f-80f0-32a57648bc31'},
 'ev5':{'standard':'fd0a74ad-a987-46a9-bab5-fc8f5245dd41'},
 'ev6':{'2WD':'f89ca39e-d0ed-4bd6-be8d-2ed031071c90','4WD':'3392db93-2dbd-4373-aefd-f40dfd4d450a'},
 'ev9':{'2WD':'ff4f5db6-fa47-42c6-8d81-45d14d0ebdcc','4WD':'f75e3468-4109-4295-a67a-faa04d0233d7'},
 'ray':{'gas':'7fc84d6d-9da4-42bf-b404-56a41b8cc179'},
 'sportage':{'gas':'01eb7ffc-c089-4f3f-8f5d-511f6fb72d42'},
 'sorento':{'gas':'56744705-8580-46f9-888c-3768406289e0'},
 'carnival':{'gas':'936a7e05-fada-4819-9597-e0aa6290a70e'}}
def add(pid,url,label,eff,unit,evidence,period,battery=None):
 p=powers[pid]
 assert (unit=='km/kWh')==(p['fuel_type']=='전기')
 if battery is not None:assert p['battery_kwh']==battery
 ident=pid+'|'+url+'|'+label+'|'+str(eff)
 sid=str(uuid.uuid5(NS,ident))
 approved.append({'id':sid,'generation_id':p['generation_id'],'powertrain_id':pid,
  'combined_efficiency':f'{eff:g} {unit} ({label} · {period})','source_url':url,'verified_at':'2026-10-27',
  'evidence':evidence,'source_record_id':str(uuid.uuid5(NS,'source|'+sid)),
  'certification_year':None,'model_year':None})
for model,f in facts.items():
 for row_index,r in enumerate(f['rows']):
  if model=='carnival' and row_index>=6:continue # later section is high-roof; never merge with ordinary body
  name,tire=r[:2];key=None;battery=None
  if model in ('ev3','ev6','ev9'):
   if '롱레인지' not in name and not(model=='ev9' and 'GT-Line' in name):continue
   key='4WD' if '4WD' in name else '2WD';battery={'ev3':81.4,'ev6':84,'ev9':99.8}[model]
  elif model=='ev4':
   if name=='스탠다드 (4WD)':continue # source contradicts specification table; no silent repair
   key='standard' if '스탠다드' in name else ('4WD' if '4WD' in name else '2WD')
   battery=58.3 if key=='standard' else 81.4
  elif model=='ev5':
   if name!='스탠다드 2WD':continue
   key='standard';battery=60.3
  else:
   prefix={'ray':'1.0 가솔린','sportage':'1.6 가솔린 터보','sorento':'2.5 가솔린 터보','carnival':'3.5 가솔린'}[model]
   if not name.startswith(prefix) or '밴' in name:continue
   key='gas'
  eff=float(re.search(r'복합\s*:\s*([0-9.]+)',r[3])[1])
  label=f'{model.upper()} {name} · {tire}'
  if battery:label+=f' · {battery:g}kWh'
  else:
   gear=re.search(r'(?:자동\s*\d+단|\d+단 DCT)',r[5]);assert gear
   label+=' · '+gear[0]
  add(M[model][key],f['url'],label,eff,'km/kWh' if battery else 'km/L',r,'제조사 현행 제원',battery)
# Historical SP2 facelift, not the new SP3 now occupying the generic Seltos webpage.
url='https://www.kia.com/content/dam/kwcms/kr/ko/files/SPR/catalog/catalog_mo_seltos.pdf'
for drive,tire,cam,eff,city,highway in [('2WD',16,False,12.8,11.5,14.6),('2WD',18,False,11.8,10.6,13.5),('2WD',16,True,12.5,11.2,14.4),('4WD',16,False,11.8,10.8,13.3),('4WD',18,False,10.8,9.8,12.2)]:
 label=f'셀토스 SP2 1.6 가솔린 터보 {drive} · {tire}인치 · 자동8단 · 빌트인 캠 '+('장착' if cam else '미장착')
 add('bbf7d74a-6e10-45de-a261-a3cff2cc7dff',url,label,eff,'km/L',{'pdf_page':27,'displacement_cc':1598,'power_ps':198,'city':city,'highway':highway},'2022-08 카탈로그')
# Korean-certified table on page 25 of the official Korean-market English catalogue.
url='https://www.hyundai.com/content/dam/hyundai/kr/ko/data/vehicles/catalog/en/ioniq6-catalog-eng.pdf'
for pid,kind,drive,battery,wheel,eff,city,highway,rng,nline in [
 ('abdce372-9b75-4dc9-8601-7fad47859879','스탠다드','2WD',63,18,6.3,6.8,5.7,437,False),
 ('d397f63e-d5b7-4864-8a4e-7933bf2b2b5b','롱레인지','2WD',84,18,6,6.4,5.4,562,False),
 ('d397f63e-d5b7-4864-8a4e-7933bf2b2b5b','롱레인지','2WD',84,20,5.1,5.5,4.6,482,False),
 ('7b8589a3-796d-45fd-bc73-baf05ee5aa5f','롱레인지','AWD',84,18,5.7,6.1,5.3,533,False),
 ('7b8589a3-796d-45fd-bc73-baf05ee5aa5f','롱레인지','AWD',84,20,4.8,5,4.5,440,False),
 ('d397f63e-d5b7-4864-8a4e-7933bf2b2b5b','롱레인지','2WD',84,20,5.1,5.5,4.6,470,True),
 ('7b8589a3-796d-45fd-bc73-baf05ee5aa5f','롱레인지','AWD',84,20,4.6,4.8,4.3,428,True)]:
 label=f'더 뉴 아이오닉 6 CE 부분변경 {kind} {drive} · {battery}kWh · {wheel}인치'+(' · N Line' if nline else '')
 add(pid,url,label,eff,'km/kWh',{'pdf_page':25,'city':city,'highway':highway,'range_km':rng},'제조사 국내 인증 제원',battery)
add('6fd70b8e-169a-475c-9382-da72b9a495d8','https://newsroom.genesis.com/ko-ko/제네시스-GV60-부분변경-모델-출시/','GV60 JW 부분변경 스탠다드 2WD · 84kWh · 19인치',5.1,'km/kWh',{'battery_kwh':84,'power_kw':168,'range_km':481},'2025-03-06 출시자료',84)
add('2040d748-d118-4b1d-bbad-3dcd5523ea4a','https://newsroom.genesis.com/ko-ko/제네시스-GV70-전-세계-동시-공개/','GV70 JK1 가솔린 2.5 터보 2WD · 18인치',10.7,'km/L',{'displacement_cc':2497,'power_ps':304,'torque_kgfm':43},'2020-12-08 공개 제원')
assert len({r['id'] for r in approved})==len(approved)
oldids={r['id'] for r in read('before-specs.json')};assert not oldids & {r['id'] for r in approved}
linked={r['powertrain_id'] for r in read('before-specs.json') if r['combined_efficiency']}
assert len({r['powertrain_id'] for r in approved}-linked)==20
(ROOT/'approved-manufacturer-specs.json').write_text(json.dumps(approved,ensure_ascii=False,indent=2))
def q(x):return "'"+str(x).replace("'","''")+"'"
sql=['BEGIN;','LOCK TABLE public.vehicle_specs, public.source_records IN SHARE ROW EXCLUSIVE MODE;', 'CREATE TEMP TABLE followup_counts(kind text,n bigint);']
for r in approved:
 cols=['id','generation_id','powertrain_id','combined_efficiency','source_url','verified_at']
 vals=','.join(q(r[c]) for c in cols)
 sql.append(f"WITH a AS (INSERT INTO public.vehicle_specs({','.join(cols)}) SELECT {vals} WHERE EXISTS(SELECT 1 FROM public.powertrains WHERE id={q(r['powertrain_id'])}::uuid AND generation_id={q(r['generation_id'])}::uuid) ON CONFLICT(id) DO NOTHING RETURNING id) INSERT INTO followup_counts SELECT 'vehicle_specs',count(*) FROM a;")
 note=json.dumps({'kind':'manufacturer_spec','certification_year':None,'model_year':None,'evidence':r['evidence']},ensure_ascii=False)
 sql.append(f"WITH a AS (INSERT INTO public.source_records(id,entity_type,entity_id,source_url,confidence,verified_at,note) VALUES ({q(r['source_record_id'])},'vehicle_spec',{q(r['id'])},{q(r['source_url'])},'A','2026-10-27',{q(note)}) ON CONFLICT(id) DO NOTHING RETURNING id) INSERT INTO followup_counts SELECT 'source_records',count(*) FROM a;")
sql+=['SELECT kind,sum(n) AS inserted FROM followup_counts GROUP BY kind;','COMMIT;']
(ROOT/'apply-manufacturer-specs.sql').write_text('\n'.join(sql))
rollback='BEGIN;\nDELETE FROM public.source_records WHERE id IN ('+','.join(q(r['source_record_id']) for r in approved)+');\nDELETE FROM public.vehicle_specs WHERE id IN ('+','.join(q(r['id']) for r in approved)+');\nCOMMIT;'
(ROOT/'rollback-manufacturer-specs.sql').write_text(rollback)
print(json.dumps({'new_specs':len(approved),'resolved_powertrains':20,'by_source':dict(collections.Counter(r['source_url'] for r in approved))},ensure_ascii=False,indent=2))
