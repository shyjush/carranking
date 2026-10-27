#!/usr/bin/env python3
"""Prepare one-time reviewed official facts and explicit, non-price market holds."""
import collections,gzip,hashlib,json,pathlib,uuid
R=pathlib.Path('research/completion-20261028');NS=uuid.UUID('5ca35648-a0dd-42f0-8394-04ed7115ac90')
def read(p):
 p=pathlib.Path(p);return json.loads(p.read_text() if p.exists() else gzip.decompress(pathlib.Path(str(p)+'.gz').read_bytes()))
def save(n,v):(R/n).write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n')
targets=read(R/'individual-candidates.json');originals=read(R/'individual-originals.json');bykey={r['key']:r for r in originals};before=read(R/'before.json')
pdfs={r['name']:r for r in read(R/'official-pdf-fetch.json')}
url=pdfs['chevrolet202211']['url'];sha=pdfs['chevrolet202211']['sha256'];catalog=[]
def price(idx,engine,trim,amount,basis,page):
 t=targets[idx];r=dict(brand='쉐보레',model=t['model'],generation_id=t['generation_id'],model_year=None,document_period='2022-11',engine=engine,trim=trim,price_krw=amount,price_basis=basis,source_url=url,source_date='2022-11',date_precision='month',document_sha256=sha,page=page,reviewed_on='2026-10-28',current_sale_verified=False,does_not_verify_depreciation=True,status='historical_official_price_only')
 r['evidence']=[{k:r[k] for k in ('source_url','source_date','document_sha256','page')}];catalog.append(r)
for trim,pre,post in [('Premier',29490000,28950000),('Premier 프라임 세이프티',31790000,31210000),('레드라인 Premier',30450000,29900000),('레드라인 Premier 프라임 세이프티',32750000,32160000)]:
 for amount,basis in [(pre,'VAT 포함·개소세 인하 전'),(post,'VAT 포함·개소세 인하 후')]:price(55,'1.35 E-Turbo · VT40 CVT',trim,amount,basis,9)
for trim,pre,post in [('LT 스페셜',30770000,30220000),('Premier 스페셜',33430000,32830000),('레드라인',33830000,33230000)]:
 for amount,basis in [(pre,'VAT 포함·개소세 인하 전'),(post,'VAT 포함·개소세 인하 후')]:price(55,'2.0 Turbo · 6단 자동',trim,amount,basis,10)
for trim,mt,cvt in [('LS Basic',9820000,11560000),('LS',10600000,12340000),('LT',11250000,12990000),('Premier',12740000,14480000)]:
 price(37,'1.0 가솔린 · 5단 수동',trim,mt,'VAT 포함·공식 판매가격',11)
 price(37,'1.0 가솔린 · C-Tech CVT',trim,cvt,'VAT 포함·공식 판매가격',11)
assert len(catalog)==22
save('official-price-catalog.json',catalog)
partials=[dict(depreciation_id=targets[11]['depreciation_id'],source_url=pdfs['ioniq5']['url'],source_date='2022-07-15 (문서에 명시된 현 모델 출시일)',price_krw=56980000,scope='아이오닉 5 NE 롱레인지 익스클루시브 · 후륜 77.4kWh · 세제혜택 전 기본가격',limitations='공식 PDF 1쪽에서 세제혜택 전 5698만원과 후 5410만원을 함께 확인했습니다. 기본 19인치와 20인치/HTRAC 선택가격을 구분합니다. 문서 출시일을 MY2023 확정으로 사용하지 않으며 계약월·옵션·보조금과 동일 사양 중고차 대조는 미완료입니다.',reviewed_on='2026-10-28',status='partial_original_price_only',does_not_verify_depreciation=True,document_sha256=pdfs['ioniq5']['sha256'],page=1),dict(depreciation_id=targets[12]['depreciation_id'],source_url='https://newsroom.porsche.com/christophorus/ko/2020/396/market-korea-porsche-korea-mid-year-press-conference-2020.html',source_date='2020-09 (원문 작성 기준월)',price_krw=145600000,scope='포르쉐 타이칸 J1 4S · 국내 출시 예정 발표가격',limitations='공식 2020년 9월 원문에서 국내 출시 예정 1억4560만원을 확인했습니다. 원문은 국내 인증 전 자료로 명시되어 있습니다. MY2021 실제 계약가격·배터리 종류·선택 옵션·세금 적용은 미확정이며 WLTP 수치를 국내 공인 전비로 사용하지 않습니다.',reviewed_on='2026-10-28',status='partial_original_price_only',does_not_verify_depreciation=True,document_sha256=read(R/'taycan-original-review.json')['sha256'])]
save('original-price-evidence.json',partials)
old=next(r for r in before['sources'] if r['entity_type']=='depreciation_price_review' and r['entity_id']==targets[11]['depreciation_id'])
resolution=dict(depreciation_id=targets[11]['depreciation_id'],supersedes_source_id=old['id'],status='resolved_tax_basis_only',source_url=partials[0]['source_url'],reviewed_on='2026-10-28',reason='이전 가격 차이 보류는 세제혜택 전 5698만원/후 5410만원의 기준 차이로 원문 확인했습니다. 기본가격 기준만 해소했으며 모델연도·계약월·옵션·실매물 대조와 감가율 검증은 계속 보류합니다.',document_sha256=partials[0]['document_sha256'],does_not_verify_depreciation=True)
save('price-resolutions.json',[resolution])
audits=[]
special={5:'후보에 TM과 이전 더 프라임, 다른 트림·등록연도가 섞여 있습니다.',6:'후보는 2022 시그니처로 표시되어 저장 2021 트렌디의 대체 표본으로 쓰지 않습니다.',7:'다른 연식의 1.6 터보와 저장 2.0 가솔린을 구분해야 합니다.',8:'후보에 하이브리드·다른 연식/트림이 섞여 있습니다.',9:'2019·2022 표기 후보와 저장 2023을 구분해야 합니다.',23:'2022·2023 표기 후보를 저장 2021 모델연도와 동일하게 취급하지 않습니다.',24:'확인한 2023 후보는 AWD로 저장 2WD와 다릅니다.',38:'2021 표기 프레스티지를 저장 2023에 대응하지 않습니다.',43:'후보의 4WD·어스 트림을 저장 에어 2WD와 혼합하지 않습니다.',44:'검색 후보에 렉스턴 스포츠 픽업과 이전 렉스턴W가 섞여 있어 Y400 SUV로 사용하지 않습니다.',45:'후보의 2WD 시그니처·2020 4WD 노블레스를 저장 2021 4WD 프레스티지로 사용하지 않습니다.',46:'프리미엄과 프레스티지를 구분하고 1.4/1.5 TSI 배기량 및 중복 매물을 확인해야 합니다.',50:'후보의 2017 프레스티지를 저장 2016 럭셔리로 사용하지 않습니다.',52:'2015 등록 스포티지R(SL)과 신규 QL 세대를 구분해야 합니다.',55:'2020 표기 매물과 저장 2021을 구분합니다. 확보한 가격표는 2022-11 적용 자료로 MY2021 가격을 확정하지 않습니다.',57:'후보의 2022 표기를 저장 2021과 혼합하지 않습니다.',60:'스포츠 옵션·구동방식과 기본형의 차이를 확인해야 합니다.',62:'2015 더 뉴 아반떼(MD)와 신규 AD 세대를 구분해야 합니다.'}
for t in targets:
 rr=[bykey[c['key']] for c in t['candidates']];ok=[r for r in rr if r.get('status')==200];sold=sum(r.get('listing_status') in ('sold','sold_or_contracted') for r in ok)
 blockers=[f"개별 후보 {len(rr)}개 중 원문 수신 {len(ok)}개, 수신 실패 {len(rr)-len(ok)}개, 판매완료·계약 표시 {sold}개입니다."]
 if not ok:blockers.append('개별 후보 원문을 수신하지 못해 가격·현재 판매 상태를 직접 확인할 수 없습니다.')
 if len(ok)>sold:blockers.append('그 외 원문도 현재 판매중 여부·관측 가격·모델연도·트림·구동·옵션·사고/주행거리와 차량별 중복 배제의 전체 조건이 확인되지 않았습니다.')
 if t['index'] in special:blockers.append(special[t['index']])
 blockers.append('동일 조건의 현재 개별 매물 최소 5대가 검증되지 않아 시세 스냅샷과 감가율 등급 상향을 보류합니다.')
 candidates=[]
 for c,r in zip(t['candidates'],rr):
  hs=r.get('headings',[]);title=next((h for h in hs if len(h)>10 and h[:4].isdigit()),r.get('title') or c['title'])
  candidates.append(dict(url=r['url'],http_status=r.get('status'),title=title[:180],listing_status=r.get('listing_status','original_unavailable'),document_sha256=r.get('sha256'),fetched_at=r.get('fetched_at'),accepted_as_snapshot=False))
 audits.append({**{k:t[k] for k in ('depreciation_id','generation_id','model','generation','model_year','target_spec')},'reviewed_on':'2026-10-28','status':'held_no_verified_market_cohort','blockers':blockers,'candidates':candidates,'candidate_count':len(rr),'originals_received':len(ok),'sold_or_contracted':sold,'does_not_verify_depreciation':True})
assert len(audits)==63 and len(bykey)==167
save('all-target-review.json',audits)
records=[]
def add(typ,eid,url,note,verified):
 ident=f'completion8:{typ}:{eid}:'+hashlib.sha256(json.dumps(note,sort_keys=True,ensure_ascii=False).encode()).hexdigest()
 records.append(dict(id=str(uuid.uuid5(NS,ident)),entity_type=typ,entity_id=eid,source_url=url,confidence='A' if verified else 'C',verified_at='2026-10-28' if verified else None,note=json.dumps(note,ensure_ascii=False)))
for r in catalog:add('generation_price_catalog',r['generation_id'],r['source_url'],r,True)
for r in partials:add('depreciation_original_price',r['depreciation_id'],r['source_url'],r,True)
add('depreciation_price_resolution',resolution['depreciation_id'],resolution['source_url'],resolution,True)
for r in audits:add('depreciation_completion_review',r['depreciation_id'],'https://github.com/shyjush/carranking/blob/main/docs/completion-review-20261028.md',r,False)
save('approved-sources.json',records)
def q(v):return 'NULL' if v is None else "'"+str(v).replace("'","''")+"'"
parts=[]
metrics={r['id']:r for r in before['depreciation']}
for i,r in enumerate(records):
 typ=r['entity_type'];eid=r['entity_id'];guard=(f"EXISTS(SELECT 1 FROM generations WHERE id={q(eid)}::uuid)" if typ=='generation_price_catalog' else f"EXISTS(SELECT 1 FROM depreciation_metrics WHERE id={q(eid)}::uuid AND confidence='C' AND original_price_krw={metrics[eid]['original_price_krw']})")
 vals=','.join(q(r[k]) for k in ('id','entity_type','entity_id','source_url','confidence','verified_at','note'))
 parts.append(f"s{i} AS (INSERT INTO source_records(id,entity_type,entity_id,source_url,confidence,verified_at,note) SELECT {vals} WHERE {guard} AND NOT EXISTS(SELECT 1 FROM source_records WHERE entity_type={q(typ)} AND entity_id={q(eid)}::uuid AND note={q(r['note'])}) ON CONFLICT(id) DO NOTHING RETURNING id,entity_type)")
sql='BEGIN;\nSELECT pg_advisory_xact_lock(20261028,8);\nWITH '+',\n'.join(parts)+', inserted AS ('+' UNION ALL '.join(f'SELECT * FROM s{i}' for i in range(len(records)))+") SELECT count(*) AS inserted,0 AS updated,count(*) FILTER(WHERE entity_type='generation_price_catalog') AS price_catalog,count(*) FILTER(WHERE entity_type='depreciation_original_price') AS price_partials,count(*) FILTER(WHERE entity_type='depreciation_price_resolution') AS price_resolutions,count(*) FILTER(WHERE entity_type='depreciation_completion_review') AS held_target_reviews,coalesce(jsonb_agg(id),'[]'::jsonb) AS ids FROM inserted;\nCOMMIT;\n"
(R/'apply-sources.sql').write_text(sql)
(R/'rollback-sources.sql').write_text('BEGIN;\nDELETE FROM source_records WHERE id IN ('+','.join(q(r['id'])+'::uuid' for r in records)+");\nCOMMIT;\n")
save('summary.json',dict(targets_reviewed=63,unique_individual_candidates=167,originals_received=sum(r.get('status')==200 for r in originals),original_errors=sum(r.get('status')!=200 for r in originals),sold_or_contracted=sum(r.get('listing_status') in ('sold','sold_or_contracted') for r in originals),new_official_price_points=22,new_partial_price_evidence=2,resolved_price_basis=1,verified_snapshots=0,verified_depreciation=0,grade_changes=0,source_records_expected=len(records)))
print(json.dumps(read(R/'summary.json'),ensure_ascii=False))
