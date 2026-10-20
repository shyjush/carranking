'use strict';
// Only independently reviewed evidence can be written. Never overwrite legacy records.
const fs=require('fs'),cp=require('child_process');
const report=JSON.parse(fs.readFileSync('evidence-worklist/validated-listings.json','utf8'));
const originalAudit=JSON.parse(fs.readFileSync('evidence-worklist/original-fetch-audit.json','utf8'));
const originalById=new Map(originalAudit.verified.map(x=>[String(x.id),x]));
const raw=fs.existsSync('evidence/inbox/value-listings.json')?JSON.parse(fs.readFileSync('evidence/inbox/value-listings.json','utf8')):[];
const byId=new Map(raw.map(x=>[String(x.candidate_id),x]));
const q=x=>"'"+String(x).replace(/'/g,"''")+"'";
const approved=report.approved.filter(a=>{
 const r=byId.get(String(a.candidate_id));
 const audit=originalById.get(String(a.candidate_id));
 return audit?.originals?.length===a.sample_size &&
 audit.originals.every((doc,i)=>doc.year_trim_price_confirmed===true&&doc.url===r?.listings?.[i]?.url) &&
 r?.independent_source_review?.status==='approved' &&
 r.independent_source_review.original_content_verified===true &&
 r.independent_source_review.cross_channel_dedupe_verified===true &&
 /^https:\/\/[^ ]+/.test(String(r.independent_source_review.evidence_report_url||'')) &&
 String(r.independent_source_review.reviewer||'').trim().length>=3;
});
const summary={submitted:report.checked,structurallyEligible:report.approved.length,independentlyApproved:approved.length,held:report.held.length+report.approved.length-approved.length};
if(!approved.length){console.log(JSON.stringify({...summary,result:'no approved evidence: no changes'}));process.exit(0)}
if(!process.env.PGPASSWORD)throw Error('Missing GitHub DB secret');
const sql=['BEGIN;'];
for(const a of approved){
 const r=byId.get(String(a.candidate_id));
 const note=['dedupe_verified=true','trim_matched=true','trim_id='+a.trim_id,'evidence_sha256='+a.evidence_sha256,'review='+r.independent_source_review.evidence_report_url].join(';');
 // Any missing exact reference price aborts the entire transaction.
 sql.push('DO $block$ DECLARE n integer; BEGIN SELECT count(*) INTO n FROM public.trims t JOIN public.powertrains p ON p.id=t.powertrain_id WHERE t.id='+q(a.trim_id)+'::uuid AND p.generation_id='+q(a.generation_id)+'::uuid AND t.model_year='+a.model_year+' AND t.price_krw='+a.original_price_krw+" AND t.source_url LIKE 'https://%'; IF n<>1 THEN RAISE EXCEPTION 'trim/source mismatch'; END IF; END $block$;");
 const cols='generation_id,model_year,as_of_date,listing_count,avg_price_krw,source_name,source_url,confidence,note';
 const source='CarRanking independently reviewed '+a.evidence_sha256;
 sql.push('INSERT INTO public.market_snapshots ('+cols+') VALUES ('+[q(a.generation_id)+'::uuid',a.model_year,q(a.observed_on),a.sample_size,a.avg_price_krw,q(source),q(a.source_urls[0]),q(a.grade),q(note)].join(',')+') ON CONFLICT (generation_id,model_year,as_of_date,source_name) DO NOTHING;');
 sql.push('INSERT INTO public.depreciation_metrics (generation_id,model_year,original_price_krw,used_price_krw,as_of_date,sample_size,confidence,note) VALUES ('+[q(a.generation_id)+'::uuid',a.model_year,a.original_price_krw,a.avg_price_krw,q(a.observed_on),a.sample_size,q(a.grade),q(note)].join(',')+') ON CONFLICT (generation_id,model_year,as_of_date) DO NOTHING;');
}
sql.push('COMMIT;');
const conn='host=aws-0-ap-northeast-2.pooler.supabase.com port=5432 dbname=postgres user=postgres.ikhyadzboorscjwcrhcz sslmode=require';
const x=cp.spawnSync('psql',[conn,'-X','-v','ON_ERROR_STOP=1'],{input:sql.join('\n'),encoding:'utf8',timeout:120000,env:process.env});
if(x.status!==0){console.error(x.stderr?.slice(-1500));process.exit(1)}
console.log(JSON.stringify({...summary,result:'write transaction succeeded; existing records preserved, actual new-row count requires DB audit'}));
