#!/usr/bin/env python3
"""Deterministic KEA variants. Explicit brand + model + generation code only.
Certification YEAR is never a model year. No current-sale claim is made.
Outputs an idempotent INSERT-only transaction, for reviewed one-time application.
"""
import collections, datetime, hashlib, json, pathlib, re, sys, uuid
SOURCE='https://www.data.go.kr/data/15139827/openapi.do'
NS=uuid.UUID('af2e75ea-672a-4b51-aacd-f3474724ab14')
def norm(s): return re.sub(r'\s+', ' ', str(s or '').strip())
def quote(s): return "'"+str(s).replace("'","''")+"'"
def plan(data, manufacturers, models, generations):
 items=data.get('items',[])
 if not isinstance(items,list) or not items or len(items)!=int(data.get('totalCount',0)): raise ValueError('Incomplete source; no writes')
 makers={x['id']:x['name'] for x in manufacturers}
 ms={x['id']:x for x in models}
 aliases={'현대':'현대','기아':'기아','제네시스':'현대'}
 groups=collections.defaultdict(list)
 for r in items:
  ident=tuple(norm(r.get(k)) for k in ('COMP_NM','MODEL_NM','YEAR','FUEL_NM','ENGINE_DISPLACEMENT','CAR_TYPE','GEAR_TYPE'))
  groups[ident].append(r)
 result=[]; reasons=collections.Counter(); duplicate=0
 for identity,rs in groups.items():
  r=rs[0]; name=norm(r.get('MODEL_NM')); maker=norm(r.get('COMP_NM'))
  variant_efficiencies={(norm(x.get('DISPLAY_EFF')),norm(x.get('URBAN_EFF')),norm(x.get('HIGHWAY_EFF')),norm(x.get('RANGE_PER_CHARGE'))) for x in rs}
  if len(variant_efficiencies)!=1:
   # These official records have identical labels but different certified efficiency.
   # A tyre/option discriminator is absent; never collapse into a misleading single value.
   reasons['indistinguishable_variants']+=len(rs);continue
  duplicate+=len(rs)-1
  if r.get('CAR_KIND')!='승용차' or re.search(r'개조|플러그인|PHEV',name,re.I): reasons['unsupported_or_conversion']+=1;continue
  fuel={'휘발유':'gas','경유':'diesel','LPG':'lpg','전기':'ev'}.get(r.get('FUEL_NM'))
  try:
   eff=float(r['DISPLAY_EFF']); year=int(r['YEAR']); cc=int(r['ENGINE_DISPLACEMENT']) if fuel!='ev' else None
   assert fuel and 0.5<=eff<=40 and 2015<=year<=datetime.date.today().year and (fuel=='ev' or 500<=cc<=9500)
  except (ValueError,TypeError,KeyError,AssertionError): reasons['invalid_or_unsupported']+=1;continue
  possible=[]
  for g in generations:
   m=ms[g['car_model_id']]; brand=makers[m['manufacturer_id']]; code=g.get('generation_code')
   if not code or maker!=aliases.get(brand): continue
   # Require model immediately followed by an explicit factory generation code.
   pattern=r'^'+re.escape(m['name'])+r'\s*\(\s*'+re.escape(code)+r'(?:\s|\))'
   if re.search(pattern,name,re.I): possible.append(g)
  # Exception for verified single-generation models without a factory code.
  # Keep it allowlisted: most trim names do not uniquely identify a generation.
  if not possible and re.fullmatch(r'(?:EV4|EV5)(?:\\s+(?:기본형|항속형|2WD|4WD|스탠다드|롱레인지|Standard|Long Range|[0-9]+인치|[0-9]+MY))*',name,re.I):
   for g0 in generations:
    m0=ms[g0['car_model_id']]
    if m0['name']!=name or g0.get('generation_code'): continue
    if maker!=aliases.get(makers[m0['manufacturer_id']]): continue
    same_model=[x for x in generations if x['car_model_id']==g0['car_model_id']]
    if len(same_model)==1: possible.append(g0)
  if len(possible)!=1: reasons['no_explicit_generation']+=1;continue
  g=possible[0]
  if year<g['start_year']-1 or (g.get('end_year') and year>g['end_year']+1): reasons['generation_year_conflict']+=1;continue
  key=hashlib.sha256('\x1f'.join(identity).encode()).hexdigest()
  pid=str(uuid.uuid5(NS,'power:'+key)); sid=str(uuid.uuid5(NS,'spec:'+key))
  label=name+' · '+str(year)+'년 인증'
  unit='km/kWh' if fuel=='ev' else 'km/L'
  result.append({'generation_id':g['id'],'powertrain_id':pid,'spec_id':sid,'name':label,'fuel_type':('하이브리드' if r.get('CAR_TYPE')=='하이브리드' else {'gas':'가솔린','diesel':'디젤','lpg':'LPG','ev':'전기'}[fuel]),'displacement_cc':cc,'efficiency':f'{eff:g} {unit} ({label})','source_key':key,'source_url':SOURCE,'certification_year':year,'raw':r})
 summary={'collected':len(items),'validated':len(result),'duplicates':duplicate,'held':sum(reasons.values()),'reasons':dict(reasons),'new_models':0,'new_generations':0}
 assert summary['validated']+summary['duplicates']+summary['held']==len(items)
 return result,summary

def sql(rows):
 # Set-based inserts avoid 600+ sequential SQL statements in one psql call.
 # All writes are INSERT-only and happen atomically; old rows are never replaced.
 statements=['BEGIN;', 'SET LOCAL lock_timeout = \'10s\';',
  'CREATE TEMP TABLE kea_stage (generation_id uuid, powertrain_id uuid, spec_id uuid, name text, fuel_type text, displacement_cc integer, efficiency text) ON COMMIT DROP;']
 for i in range(0,len(rows),200):
  values=[]
  for r in rows[i:i+200]:
   cc=str(r['displacement_cc']) if r['displacement_cc'] is not None else 'NULL'
   values.append('('+','.join((quote(r['generation_id'])+'::uuid',quote(r['powertrain_id'])+'::uuid',quote(r['spec_id'])+'::uuid',quote(r['name']),quote(r['fuel_type']),cc,quote(r['efficiency'])))+')')
  statements.append('INSERT INTO kea_stage VALUES '+','.join(values)+';')
 statements.extend([
  """WITH inserted AS (
   INSERT INTO public.powertrains(id,generation_id,name,fuel_type,displacement_cc)
   SELECT DISTINCT s.powertrain_id,s.generation_id,s.name,s.fuel_type,s.displacement_cc
   FROM kea_stage s JOIN public.generations g ON g.id=s.generation_id
   ON CONFLICT(id) DO NOTHING RETURNING id
  ) SELECT 'powertrains|'||count(*) FROM inserted;""",
  """WITH inserted AS (
   INSERT INTO public.vehicle_specs(id,generation_id,powertrain_id,combined_efficiency,source_url,verified_at)
   SELECT DISTINCT s.spec_id,s.generation_id,s.powertrain_id,s.efficiency,"""+quote(SOURCE)+""",CURRENT_DATE
   FROM kea_stage s JOIN public.powertrains p ON p.id=s.powertrain_id AND p.generation_id=s.generation_id
   ON CONFLICT(id) DO NOTHING RETURNING id
  ) SELECT 'specs|'||count(*) FROM inserted;""",
  'COMMIT;'
 ])
 return '\\n'.join(statements)

if __name__=='__main__':
 stage,dbdir,out=sys.argv[1:]; db=pathlib.Path(dbdir);out=pathlib.Path(out);out.mkdir(parents=True,exist_ok=True)
 rows,summary=plan(json.load(open(stage)),*[json.load(open(db/(t+'.json'))) for t in ('manufacturers','models','generations')])
 (out/'approved-variants.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2))
 (out/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2))
 (out/'apply.sql').write_text(sql(rows))
 print(json.dumps(summary,ensure_ascii=False))
