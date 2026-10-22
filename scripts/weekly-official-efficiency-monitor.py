#!/usr/bin/env python3
"""Weekly evidence monitor. Read-only; never writes unverified efficiency to production."""
import csv, os, pathlib, subprocess, urllib.request, urllib.error, datetime, json, html
out=pathlib.Path('official-economy-reports')
out.mkdir(exist_ok=True)
date=datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=9))).isoformat(timespec='seconds')
conn='host=aws-0-ap-northeast-2.pooler.supabase.com port=5432 dbname=postgres user=postgres.ikhyadzboorscjwcrhcz sslmode=require'
sql="""COPY (
 SELECT d.brand,d.model,COALESCE(d.generation_code,''),p.id,p.generation_id,p.name,p.fuel_type,COALESCE(p.displacement_cc::text,'')
 FROM public.powertrains p
 JOIN public.web_vehicle_detail d ON d.generation_id=p.generation_id
 WHERE NOT EXISTS (
  SELECT 1 FROM public.vehicle_specs s
  WHERE s.powertrain_id=p.id AND s.generation_id=p.generation_id
  AND s.source_url LIKE 'https://%' AND COALESCE(s.combined_efficiency,'')<>''
 )
 ORDER BY d.brand,d.model,p.name
) TO STDOUT WITH CSV HEADER"""
if not os.environ.get('PGPASSWORD'):
 raise SystemExit('SUPABASE_DB_PASSWORD secret missing: fail closed')
res=subprocess.run(['psql',conn,'-v','ON_ERROR_STOP=1','-c',sql],capture_output=True,text=True,check=True)
(out/'missing-powertrains.csv').write_text(res.stdout,encoding='utf-8')
rows=list(csv.DictReader(res.stdout.splitlines()))
sources=[
 ('기아 공식 차량 제원','https://www.kia.com/kr/vehicles/k8/specification'),
 ('기아 니로 제원','https://www.kia.com/kr/vehicles/niro/specification'),
 ('제네시스 GV80 제원','https://www.genesis.com/kr/ko/models/luxury-suv-genesis/gv80/specs.html')
]
checks=[]
for title,url in sources:
 try:
  req=urllib.request.Request(url,headers={'User-Agent':'CarRankingOfficialCoverageMonitor/1.0'})
  with urllib.request.urlopen(req,timeout=18) as response:
   payload=response.read(300_000)
   checks.append({'source':title,'url':url,'status':response.status,'received_bytes':len(payload)})
 except (urllib.error.HTTPError, urllib.error.URLError,TimeoutError) as exc:
  checks.append({'source':title,'url':url,'error':str(exc)[:150]})
summary={'checked_at_kst':date,'missing_powertrain_rows':len(rows),'source_checks':checks,'mode':'read-only: no guessing, no DB writes','next_action':'Review manufacturer source and exact wheel/drivetrain trim before registering any new efficiency'}
(out/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
lines=['# CarRanking 공식 연비 누락자료 점검',f'- 확인 시각: {date}',f'- 공식 연비 미등록 파워트레인: {len(rows)}건','- 출처 점검:']
lines.extend(f"  - {c['source']}: HTTP {c.get('status','확인 불가')} ({c.get('error','응답 확인')})" for c in checks)
lines.extend(['- DB 자동 입력: **하지 않음** (현재 공식 웹페이지의 사양별 숫자까지 자동 검증할 수 없어 안전 차단)','- 누락 차량 상세는 아티팩트의 missing-powertrains.csv 참조'])
(out/'summary.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print('\n'.join(lines))
