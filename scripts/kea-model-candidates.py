"""Read-only discovery classification; never authorizes model/generation/spec writes."""
import collections,re

def compact(value):
 return re.sub(r'\s+','',str(value or '')).casefold()

def discover(items,manufacturers,models):
 makers={x['id']:x['name'] for x in manufacturers}
 aliases={'제네시스':'현대'}
 known=collections.defaultdict(set)
 for m in models:
  name=makers.get(m['manufacturer_id'])
  known[aliases.get(name,name)].add(compact(m['name']))
 # Keep the original raw discovery count for audit continuity. It is not a
 # count of verified new models. Model-year/launch/current sale remain unknown.
 raw=collections.defaultdict(lambda:{'records':0,'years':set(),'examples':set()})
 exact={(aliases.get(makers.get(m['manufacturer_id']),makers.get(m['manufacturer_id'])),str(m['name']).strip().casefold()) for m in models}
 for item in items:
  if item.get('CAR_KIND')!='승용차':continue
  maker=str(item.get('COMP_NM') or '').strip();label=str(item.get('MODEL_NM') or '').strip()
  hit=re.match(r'^([가-힣A-Za-z0-9][가-힣A-Za-z0-9 -]{1,45}?)\s*\(([A-Za-z][A-Za-z0-9 -]{1,12})\)',label)
  if not hit or maker not in ('현대','기아'):continue
  model=hit.group(1).strip()
  if (maker,model.casefold()) in exact:continue
  c=raw[(maker,model)];c['records']+=1;c['years'].add(str(item.get('YEAR','')));c['examples'].add(label)
 candidates=[];excluded=[]
 for (maker,model),c in sorted(raw.items()):
  row={'manufacturer':maker,'model_candidate':model,'source':'KEA','records':c['records'],'certification_years':sorted(c['years']),'examples':sorted(c['examples'])[:3]}
  key=compact(model)
  if re.search(r'개조|플러그인|PHEV',model,re.I):reason='unsupported_conversion'
  elif key in known[maker]:reason='existing_model_name_alias'
  else:
   # Recognized option suffixes classify only discovery noise. They must never
   # be reused by the strict generation/efficiency matcher as identity proof.
   variant=False
   for name in sorted(known[maker],key=len,reverse=True):
    if key.startswith(name) and re.match(r'^(?:항속형|기본형|일렉트릭|롱레인지|스탠다드|[24]wd|rwd|awd|\d+인치)',key[len(name):]):
     variant=True;break
   reason='existing_model_variant' if variant else None
  if reason:
   row.update(status='excluded_from_new_model_candidates',reason=reason);excluded.append(row)
  else:
   row['status']='review_required_not_published';candidates.append(row)
 return {'count':len(candidates),'raw_candidate_count':len(raw),'excluded_count':len(excluded),'candidates':candidates,'excluded':excluded}
