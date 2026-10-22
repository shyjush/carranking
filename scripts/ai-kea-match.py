#!/usr/bin/env python3
"""Bounded AI suggestions for KEA/CarRanking discrepancies. NEVER writes to DB."""
import csv,json,os,pathlib,re,subprocess,urllib.request,urllib.error
root=pathlib.Path("official-economy-reports");root.mkdir(exist_ok=True)
result={"status":"disabled","calls":0,"suggestions":0,"note":"AI suggestions require deterministic independent verification; no database writes"}
out=root/"ai-matching-suggestions.json"
def done():
 out.write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding="utf-8")
 print(json.dumps(result,ensure_ascii=False))
key=os.getenv("OPENAI_API_KEY","").strip()
if not key:
 result["status"]="skipped: OPENAI_API_KEY not configured";done();raise SystemExit(0)
stage=root/"kea-pending-review.csv"
if not stage.exists():
 result["status"]="skipped: no unmatched evidence";done();raise SystemExit(0)
rows=list(csv.DictReader(stage.open(encoding="utf-8-sig")))
conn="host=aws-0-ap-northeast-2.pooler.supabase.com port=5432 dbname=postgres user=postgres.ikhyadzboorscjwcrhcz sslmode=require"
q=subprocess.run(["psql",conn,"-X","-v","ON_ERROR_STOP=1","--csv","-c","select p.id as powertrain_id,d.brand,d.model,p.name as powertrain,p.fuel_type,p.displacement_cc from public.powertrains p join public.web_vehicle_detail d on d.generation_id=p.generation_id where not exists(select 1 from public.vehicle_specs s where s.powertrain_id=p.id and coalesce(s.combined_efficiency,'')<>'')"],capture_output=True,text=True)
if q.returncode:raise SystemExit("Database read failed")
db=list(csv.DictReader(q.stdout.splitlines()))
def norm(v):return re.sub(r"[^a-z0-9가-힣]","",str(v or "").lower())
def compatible(r,p):
 if r["fuel"] not in ("ev","gas","diesel","lpg"):return False
 ff=norm(p["fuel_type"])
 mapping={"ev":["전기","electric"],"gas":["가솔린","휘발유","하이브리드"],"diesel":["디젤","경유"],"lpg":["lpg"]}
 if not any(word in ff for word in mapping[r["fuel"]]):return False
 if r["fuel"]!="ev":
  try:
   if abs(int(float(r["displacement"]))-int(p["displacement_cc"]))>3:return False
  except (ValueError,TypeError):return False
 return True
limit=min(8,max(0,int(os.getenv("AI_MATCH_MAX_CALLS","8"))))
model=os.getenv("OPENAI_MATCH_MODEL","gpt-4o-mini")
seen=set()
result["status"]="complete"
result["model"]=model
result["call_cap"]=limit
proposals=[]
for r in rows:
 if result["calls"]>=limit:break
 if not r.get("official_model") or not r.get("efficiency"):continue
 name=norm(r["official_model"])
 options=[p for p in db if compatible(r,p) and (norm(p["model"]) in name or norm(p["model"])[:3] in name)]
 if len(options)<1 or len(options)>8:continue
 signature=(r["official_model"],r["year"],r["fuel"],r["efficiency"])
 if signature in seen:continue
 seen.add(signature)
 payload={"model":model,"store":False,"max_output_tokens":300,"input":[{"role":"system","content":"You assist a Korean vehicle data curator. Choose one id from CANDIDATES only if the official vehicle name unambiguously matches the brand, generation, drivetrain and motor/engine; otherwise return NONE. Never invent identifiers. Reply a JSON object with keys candidate_id and reason; reason short."},{"role":"user","content":json.dumps({"official_record":r,"candidates":options},ensure_ascii=False)}],"text":{"format":{"type":"json_object"}}}
 req=urllib.request.Request("https://api.openai.com/v1/responses",data=json.dumps(payload).encode(),headers={"Authorization":"Bearer "+key,"Content-Type":"application/json"},method="POST")
 result["calls"]+=1
 try:
  with urllib.request.urlopen(req,timeout=35) as resp:data=json.loads(resp.read())
  texts=[c.get("text","") for item in data.get("output",[]) for c in item.get("content",[]) if c.get("type")=="output_text"]
  answer=json.loads("".join(texts))
  selected=str(answer.get("candidate_id",""))
  if selected!="NONE" and any(p["powertrain_id"]==selected for p in options):
   proposals.append({"official_model":r["official_model"],"year":r["year"],"efficiency":r["efficiency"],"candidate_powertrain_id":selected,"reason":str(answer.get("reason",""))[:150],"status":"review_only"})
 except (urllib.error.HTTPError,urllib.error.URLError,TimeoutError,ValueError) as e:
  result.setdefault("errors",[]).append(type(e).__name__)
result["suggestions"]=len(proposals)
result["review_only_candidates"]=proposals
result["note"]="AI proposals only; no modifications to vehicle_specs, generations or official rankings"
done()
