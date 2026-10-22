#!/usr/bin/env python3
"""Import only human-reviewed manufacturer fuel efficiency rows; never scrape guessed numbers.

Reviewed CSV columns: generation_id,powertrain_id,combined_efficiency,source_url,reviewed_at,review_note
Only exact reviewed rows and exact registered powertrains can be inserted; existing data is never modified.
"""
import csv, json, os, pathlib, re, subprocess, sys, datetime
out=pathlib.Path('official-economy-reports')
out.mkdir(exist_ok=True)
csvpath=pathlib.Path('data/reviewed-official-efficiency.csv')
fields=['generation_id','powertrain_id','combined_efficiency','source_url','reviewed_at','review_note']
rows=list(csv.DictReader(csvpath.open(encoding='utf-8-sig',newline='')))
conn='host=aws-0-ap-northeast-2.pooler.supabase.com port=5432 dbname=postgres user=postgres.ikhyadzboorscjwcrhcz sslmode=require'
uuid=re.compile(r'^[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$')
eff=re.compile(r'^([0-9]+(?:\.[0-9]+)?)\s*km\s*/\s*(L|kWh)\s*\([^)]{12,220}\)$',re.I)
if not os.environ.get('PGPASSWORD'):
 raise SystemExit('BLOCKED: SUPABASE_DB_PASSWORD secret missing')
if rows:
 if not all(set(fields)<=set(r) for r in rows):
  raise SystemExit('BLOCKED: reviewed file fields missing')
 for row in rows:
  if not uuid.fullmatch(row['generation_id']) or not uuid.fullmatch(row['powertrain_id']):
   raise SystemExit('BLOCKED: invalid UUID')
  m=eff.fullmatch(row['combined_efficiency'])
  if not m or not (0.5<=float(m.group(1))<=60):
   raise SystemExit('BLOCKED: invalid/ambiguous efficiency format')
  if not row['source_url'].startswith(('https://www.kia.com/kr/','https://www.hyundai.com/kr/','https://www.genesis.com/kr/')):
   raise SystemExit('BLOCKED: unsupported official manufacturer source')
  reviewed=datetime.date.fromisoformat(row['reviewed_at'])
  if not (datetime.date(2026,1,1)<=reviewed<=datetime.date.today()):
   raise SystemExit('BLOCKED: invalid review date')
  if len(row['review_note'].strip())<18:
   raise SystemExit('BLOCKED: missing trim/wheel/drivetrain review note')
 pairs=[r['powertrain_id'] for r in rows]
 if len(pairs)!=len(set(pairs)):raise SystemExit('BLOCKED: duplicated powertrain in reviewed queue')

def q(s):return "'"+str(s).replace("'","''")+"'"
values=','.join('('+','.join(q(row[k]) for k in fields)+')' for row in rows)
if rows:
 sql="""
 BEGIN;
 CREATE TEMP TABLE reviewed_queue (generation_id uuid,powertrain_id uuid,combined_efficiency text,source_url text,reviewed_at date,review_note text) ON COMMIT DROP;
 INSERT INTO reviewed_queue VALUES %s;
 DO $$
 BEGIN
  IF EXISTS (
   SELECT 1 FROM reviewed_queue q
   LEFT JOIN public.powertrains p ON p.id=q.powertrain_id AND p.generation_id=q.generation_id
   WHERE p.id IS NULL OR
     (q.combined_efficiency ~* 'km\\s*/\\s*kWh') <> (p.fuel_type ~* '전기|electric|^EV$')
  ) THEN RAISE EXCEPTION 'Official review candidate does not match existing vehicle powertrain or fuel unit'; END IF;
 END $$;
 INSERT INTO public.vehicle_specs(generation_id,powertrain_id,combined_efficiency,source_url,verified_at)
 SELECT q.generation_id,q.powertrain_id,q.combined_efficiency,q.source_url,q.reviewed_at
 FROM reviewed_queue q
 WHERE NOT EXISTS (SELECT 1 FROM public.vehicle_specs s WHERE s.powertrain_id=q.powertrain_id)
 AND NOT EXISTS (SELECT 1 FROM public.vehicle_specs s WHERE s.generation_id=q.generation_id AND s.powertrain_id=q.powertrain_id);
 COMMIT;
 """%values
 p=subprocess.run(['psql',conn,'-X','-v','ON_ERROR_STOP=1','-t','-c',sql],capture_output=True,text=True)
 if p.returncode:
  print(p.stderr,file=sys.stderr)
  raise SystemExit('BLOCKED: reviewed import transaction failed')
 insert_lines=[x for x in p.stdout.splitlines() if x.strip().startswith('INSERT 0 ')]
 inserted=int(insert_lines[-1].split()[-1]) if insert_lines else 0
else:inserted=0
status={'reviewed_queue_rows':len(rows),'new_db_records':inserted,'unchanged_existing_rows':len(rows)-inserted,'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'mode':'reviewed-only fail-closed insert'}
(out/'reviewed-import.json').write_text(json.dumps(status,ensure_ascii=False,indent=2),encoding='utf-8')
with (out/'summary.md').open('a',encoding='utf-8') as f:
 f.write('\n## 사전 검토된 공식 연비 적용\n')
 f.write(f'- 검토 대기열 {len(rows)}건 중 새로 등록 {inserted}건 (기존값 덮어쓰기 없음)\n')
print(json.dumps(status,ensure_ascii=False))
