#!/usr/bin/env python3
"""Safely maintain a separate, source-year-labelled official KEA vehicle catalog.

Original CarRanking manufacturer/model/generation/powertrain rows are NEVER created or changed.
Only eligible complete passenger-car certification rows are upserted idempotently.
"""
import csv, datetime as dt, hashlib, json, os, pathlib, re, subprocess
from decimal import Decimal, InvalidOperation
p=pathlib.Path("official-economy-reports")
p.mkdir(exist_ok=True)
stage=p/"kea-all-pages-staging.json"
report={"status":"not configured","read":0,"eligible":0,"unique":0,"upserted":0,"new":0,"updated":0,"unchanged":0,"rejected":{}}
def finish():
 (p/"kea-catalog-import.json").write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding="utf-8")
 print(json.dumps(report,ensure_ascii=False))
if not stage.exists():
 finish();raise SystemExit(0)
if not os.getenv("PGPASSWORD"):raise SystemExit("Missing SUPABASE_DB_PASSWORD")
data=json.loads(stage.read_text(encoding="utf-8"))
items=data.get("items")
if not isinstance(items,list) or len(items)!=int(data.get("totalCount",0)):
 raise SystemExit("Incomplete KEA source list, no DB writes")
report["read"]=len(items)
def q(x):return "'"+str(x).replace("'","''")+"'"
def rejected(reason):
 report["rejected"][reason]=report["rejected"].get(reason,0)+1
rows={}
for item in items:
 if not isinstance(item,dict):rejected("bad_record");continue
 if item.get("CAR_KIND","").strip()!="승용차":rejected("non_passenger");continue
 maker=str(item.get("COMP_NM") or "").strip()
 model=str(item.get("MODEL_NM") or "").strip()
 year=str(item.get("YEAR") or "").strip()
 fuel=str(item.get("FUEL_NM") or "").strip()
 if not maker or len(model)<2 or len(model)>170 or not re.fullmatch(r"20\d{2}",year):
  rejected("incomplete_identity");continue
 year=int(year)
 if year<2015 or year>dt.date.today().year:rejected("old_or_future");continue
 fuel_map={"휘발유":"gas","경유":"diesel","LPG":"lpg","전기":"ev"}
 fuel_type=fuel_map.get(fuel)
 if not fuel_type:rejected("mixed_or_unrecognized_fuel");continue
 try: eff=Decimal(str(item.get("DISPLAY_EFF") or ""))
 except InvalidOperation:rejected("invalid_efficiency");continue
 if eff<Decimal("0.5") or eff>Decimal("40"):rejected("invalid_efficiency");continue
 rawcc=str(item.get("ENGINE_DISPLACEMENT") or "")
 cc=None if fuel_type=="ev" else (int(rawcc) if rawcc.isdigit() else None)
 if fuel_type!="ev" and (cc is None or cc<500 or cc>9500):rejected("invalid_cc");continue
 # Distinct year/model/fuel/cc/eff are distinct manufacturer-certified versions.
 identity="\x1f".join([maker,model,str(year),fuel,str(cc),str(eff)])
 key=hashlib.sha256(identity.encode("utf-8")).hexdigest()
 rows[key]=(maker,model,year,fuel_type,cc,eff,fuel)
report["eligible"]=sum(report["rejected"].values())+len(rows)
report["unique"]=len(rows)
conn="host=aws-0-ap-northeast-2.pooler.supabase.com port=5432 dbname=postgres user=postgres.ikhyadzboorscjwcrhcz sslmode=require"
allrows=list(rows.items())
for i in range(0,len(allrows),150):
 batch=allrows[i:i+150]
 parts=[]
 for key,(maker,model,year,fuel_type,cc,eff,fuel) in batch:
  values=[q(key),q(maker),q(model),str(year),q(fuel_type),str(cc) if cc is not None else "NULL",str(eff),q(fuel)]
  parts.append("("+",".join(values)+")")
 sql="""WITH incoming(source_key,manufacturer,model_detail,certification_year,fuel_type,displacement_cc,combined_efficiency,official_fuel_name) AS (VALUES %s),
 existing AS (
   SELECT i.source_key, e.source_key AS existing_key,
    (e.manufacturer,e.model_detail,e.certification_year,e.fuel_type,e.displacement_cc,e.combined_efficiency,e.official_fuel_name)
    IS DISTINCT FROM
    (i.manufacturer,i.model_detail,i.certification_year,i.fuel_type,i.displacement_cc,i.combined_efficiency,i.official_fuel_name) AS changed
   FROM incoming i LEFT JOIN public.kea_official_vehicle_specs e ON e.source_key=i.source_key
 ),
 applied AS (
  INSERT INTO public.kea_official_vehicle_specs(source_key,manufacturer,model_detail,certification_year,fuel_type,displacement_cc,combined_efficiency,official_fuel_name)
  SELECT * FROM incoming
  ON CONFLICT (source_key) DO UPDATE
  SET manufacturer=excluded.manufacturer,model_detail=excluded.model_detail,
  certification_year=excluded.certification_year,fuel_type=excluded.fuel_type,
  displacement_cc=excluded.displacement_cc,combined_efficiency=excluded.combined_efficiency,
  official_fuel_name=excluded.official_fuel_name,refreshed_at=now()
  WHERE (public.kea_official_vehicle_specs.manufacturer,public.kea_official_vehicle_specs.model_detail,public.kea_official_vehicle_specs.certification_year,public.kea_official_vehicle_specs.fuel_type,public.kea_official_vehicle_specs.displacement_cc,public.kea_official_vehicle_specs.combined_efficiency,public.kea_official_vehicle_specs.official_fuel_name)
   IS DISTINCT FROM
   (excluded.manufacturer,excluded.model_detail,excluded.certification_year,excluded.fuel_type,excluded.displacement_cc,excluded.combined_efficiency,excluded.official_fuel_name)
  RETURNING source_key
 )
 SELECT
 (SELECT count(*) FROM existing WHERE existing_key IS NULL) AS new,
 (SELECT count(*) FROM existing WHERE existing_key IS NOT NULL AND changed) AS updated,
 (SELECT count(*) FROM existing WHERE existing_key IS NOT NULL AND NOT changed) AS unchanged,
 (SELECT count(*) FROM applied) AS written;"""%(",".join(parts))
 result=subprocess.run(["psql",conn,"-X","-v","ON_ERROR_STOP=1","--csv","-c",sql],capture_output=True,text=True,timeout=70)
 if result.returncode:raise SystemExit("KEA catalog DB write rejected: "+result.stderr[-280:])
 counts=list(csv.DictReader(result.stdout.splitlines()))
 if len(counts)!=1:raise SystemExit("Missing catalog write counts")
 for field in ("new","updated","unchanged"):report[field]+=int(counts[0][field])
 if int(counts[0]["written"])!=int(counts[0]["new"])+int(counts[0]["updated"]):raise SystemExit("Catalog write counts inconsistent")
report["upserted"]=report["new"]+report["updated"]
if report["new"]+report["updated"]+report["unchanged"]!=report["unique"]:raise SystemExit("Catalog counts do not add up")
report["status"]="complete"
report["upserted"]=len(rows)
finish()
