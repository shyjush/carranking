'use strict';
// Fetch evidence originals in CI; never infer approval from submitter-provided fields.
// Sites which block automation are held for independent manual inspection.
const fs=require('node:fs'),crypto=require('node:crypto');
const input='evidence/inbox/value-listings.json',out='evidence-worklist/original-fetch-audit.json';
fs.mkdirSync('evidence-worklist',{recursive:true});
const rows=fs.existsSync(input)?JSON.parse(fs.readFileSync(input,'utf8')):[];
if(!Array.isArray(rows))throw Error('Expected candidate array');
const report={checked:0,verified:[],held:[]};
const words=x=>String(x||'').normalize('NFKC').replace(/<[^>]*>/g,' ').replace(/&nbsp;/g,' ').replace(/\s+/g,' ').trim().toLowerCase();
function safeUrl(raw){
 const u=new URL(raw);
 if(u.protocol!=='https:'||u.username||u.password||u.port&&u.port!=='443'||!u.hostname.includes('.')||/^(localhost|127\.|10\.|192\.168\\.|169\.254\\.)/.test(u.hostname))throw Error('URL policy');
 return u;
}
async function fetchOriginal(url){
 const u=safeUrl(url);
 const ctrl=new AbortController(),timer=setTimeout(()=>ctrl.abort(),12000);
 try{
  const r=await fetch(u,{redirect:'error',signal:ctrl.signal,headers:{'User-Agent':'CarRankingEvidenceAudit/1.0 (public evidence only)','Accept':'text/html'}});
  if(!r.ok||!String(r.headers.get('content-type')||'').includes('text/html'))throw Error('HTTP/content-type blocked: '+r.status);
  const size=Number(r.headers.get('content-length')||0);if(size>1000000)throw Error('oversized original');
  const content=await r.text();if(content.length>1000000)throw Error('oversized original');
  return {text:words(content),sha256:crypto.createHash('sha256').update(content).digest('hex')};
 }finally{clearTimeout(timer)}
}
(async()=>{
 for(const [idx,c] of rows.entries()){
  const id=String(c?.candidate_id??idx);report.checked++;
  if(!Array.isArray(c?.listings)||!c.listings.length){report.held.push({id,reason:'no individual listings'});continue}
  const docs=[];let reason='';
  for(const l of c.listings){
   try{
    const original=await fetchOriginal(l.url);
    // Positive matching must be confirmed on original page. Unverifiable text => hold.
    const checks=[String(c.model_year),String(l.trim_name||''),String(l.price_krw||'')].filter(Boolean);
    const compact=x=>words(x).replace(/[^0-9a-z가-힣]/g,'');
    const page=compact(original.text);
    if(!checks.every(v=>page.includes(compact(v))))throw Error('year, trim or exact price missing in live original');
    docs.push({url:l.url,sha256:original.sha256,observed_at:new Date().toISOString(),year_trim_price_confirmed:true});
   }catch(e){reason='original inaccessible or mismatched: '+String(e.message).slice(0,180);break}
  }
  if(reason)report.held.push({id,reason});
  else report.verified.push({id,originals:docs,review_status:'pending_independent_dedupe_and_trim_review'});
 }
 fs.writeFileSync(out,JSON.stringify(report,null,2)+'\n');
 console.log(JSON.stringify({checked:report.checked,original_pages_verified:report.verified.length,held:report.held.length}));
})().catch(e=>{console.error(e);process.exit(1)});
