#!/usr/bin/env python3
"""Audit all stored valuations against public aggregate originals.
Aggregates are context only; never mint individual listings or promote confidence.
"""
import concurrent.futures,hashlib,html,json,pathlib,re,urllib.parse,urllib.request
R=pathlib.Path('research/followup-20261027')
def read(n):return json.loads((R/('before-'+n+'.json')).read_text())
gs={r['id']:r for r in read('generations')};ms={r['id']:r for r in read('models')}
def plain(s):return re.sub(r'\s+',' ',html.unescape(re.sub('<[^>]+>',' ',s))).strip()
def audit(d):
 g=gs[d['generation_id']];model=ms[g['car_model_id']]['name']
 url='https://lgeal-agent.bigvalue.ai/dashboard/car/'+urllib.parse.quote(model)+'/'+str(d['model_year'])
 result={'depreciation_id':d['id'],'model':model,'generation':g.get('generation_code') or g['name'],'model_year':d['model_year'],'stored_note':d['note'],'stored_confidence':d['confidence'],'aggregate_url':url,'checked_on':'2026-10-27','decision':'held','missing':[]}
 result['missing']=['동일 세대·연식·엔진·구동·트림의 개별 매물 URL 및 매물 ID','주행거리·사고/수리 이력·옵션 차이','동일 관측일의 매물 가격 및 차량 중복 확인','해당 연식 공식 가격표와 세금·옵션 조건']
 try:
  response=urllib.request.urlopen(url,timeout=20);raw=response.read();text=raw.decode();body=plain(text)
  tables=re.findall(r'<tr[^>]*>(.*?)</tr>',text,re.S)
  result['aggregate_fetch']={'status':response.status,'sha256':hashlib.sha256(raw).hexdigest(),'table_rows':[[plain(t) for t in re.findall(r'<t[dh][^>]*>(.*?)</t[dh]>',row,re.S)] for row in tables], 'date_labels':re.findall(r'(?:데이터 기준|기준일|업데이트)\s*\d{4}[.\-]\d{2}[.\-]\d{2}',body)}
  result['reason']='집계 원문을 조회했으나 개별 매물의 사양·중복·상태를 확인할 수 없어 감가율 검증에 사용하지 않음'
 except Exception as e:result['reason']='집계 원문 접근 실패: '+str(e)[:180]
 return result
if __name__=='__main__':
 with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:rows=list(pool.map(audit,read('depreciation')))
 (R/'depreciation-audit.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2))
 print(json.dumps({'checked':len(rows),'aggregate_originals_received':sum('aggregate_fetch' in r for r in rows),'eligible_individual_snapshots':0,'grades_changed':0},ensure_ascii=False))
