'use strict';
// Strict, fail-closed CarRanking individual listing validator.
// No crawling of restricted marketplaces and no automatic invention of evidence.
const fs=require('node:fs');
const crypto=require('node:crypto');
const input=process.argv[2]||'evidence/inbox/value-listings.json';
const result=process.argv[3]||'evidence-worklist/validated-listings.json';
fs.mkdirSync('evidence-worklist',{recursive:true});
const report={checked:0,approved:[],held:[],source:input};
function reject(id,reason){report.held.push({id,reason});}
const clean=x=>String(x??'').normalize('NFKC').trim().replace(/\s+/g,' ').toLowerCase();
const validUrl=x=>{try{const u=new URL(x);return u.protocol==='https:'&&!!u.hostname&&!['example.com','localhost'].includes(u.hostname)}catch{return false}};
const canonical=x=>{const u=new URL(x);u.hash='';for(const k of [...u.searchParams.keys()])if(/^utm_/i.test(k)||['fbclid','gclid'].includes(k.toLowerCase()))u.searchParams.delete(k);u.searchParams.sort();return u.toString().replace(/\/$/,'')};
const today=new Intl.DateTimeFormat('en-CA',{timeZone:'Asia/Seoul',year:'numeric',month:'2-digit',day:'2-digit'}).format(new Date());
const date=x=>typeof x==='string'&&/^\d{4}-\d{2}-\d{2}$/.test(x)&&!isNaN(Date.parse(x))&&new Date(x).toISOString().slice(0,10)===x&&x<=today;
let rows=[];
try{if(fs.existsSync(input)){const raw=JSON.parse(fs.readFileSync(input,'utf8'));if(!Array.isArray(raw))throw Error('Input must be an array');rows=raw}}catch(e){console.error('Invalid evidence input',e.message);process.exit(2)}
for(const [i,r] of rows.entries()){
 const id=String(r?.candidate_id||i);report.checked++;
 if(!r||typeof r!=='object'){reject(id,'invalid record');continue}
 const {generation_id,model_year,trim_id,trim_name,powertrain_name,original_price_krw,original_source_url,observed_on,listings,source_permission}=r;
 if(!/^[0-9a-f-]{36}$/i.test(String(generation_id))||!/^[0-9a-f-]{36}$/i.test(String(trim_id))||!Number.isInteger(model_year)||model_year<1990||model_year>2100){reject(id,'missing exact DB identity');continue}
 if(!clean(trim_name)||!clean(powertrain_name)||!Number.isSafeInteger(original_price_krw)||original_price_krw<=0||!validUrl(original_source_url)){reject(id,'unverified original trim price');continue}
 if(!date(observed_on)||source_permission!=='public-permitted'){reject(id,'invalid observation date or source permission');continue}
 if(!Array.isArray(listings)||listings.length<5||listings.length>100){reject(id,'insufficient/oversized individual listings');continue}
 const c=r.cohort;
 if(!c||!clean(c.drivetrain)||!clean(c.transmission)||!clean(c.option_basis)||!['no_accident','simple_repair','structural_repair'].includes(c.accident_status)||!Number.isSafeInteger(c.mileage_min_km)||!Number.isSafeInteger(c.mileage_max_km)||c.mileage_min_km<0||c.mileage_max_km<c.mileage_min_km){reject(id,'missing drivetrain, transmission, options or condition/mileage cohort');continue}
 const seen=new Set(),fingerprints=new Set(),prices=[];let error=null;
 for(const item of listings){
  if(!item||!validUrl(item.url)||!date(item.observed_on)||item.observed_on!==observed_on||!Number.isSafeInteger(item.price_krw)||item.price_krw<=0||item.model_year!==model_year||clean(item.trim_name)!==clean(trim_name)||clean(item.powertrain_name)!==clean(powertrain_name)||String(item.generation_id)!==String(generation_id)){error='source, date, year, generation, powertrain or trim mismatch';break}
  if(item.listing_status!=='for_sale'||item.observation_source!=='direct_original'||!/^([a-f0-9]{64})$/i.test(String(item.original_content_sha256||''))||!validUrl(item.condition_source_url)||!Number.isSafeInteger(item.mileage_km)||item.mileage_km<c.mileage_min_km||item.mileage_km>c.mileage_max_km||item.accident_status!==c.accident_status||clean(item.drivetrain)!==clean(c.drivetrain)||clean(item.transmission)!==clean(c.transmission)||clean(item.option_basis)!==clean(c.option_basis)){error='inactive/unobserved listing or missing/mismatched mileage, accident, drivetrain, transmission or options';break}
  if(!item.listing_id||!item.seller_or_vin_fingerprint){error='missing listing ID or cross-channel duplicate fingerprint';break}
  const u=canonical(item.url),fingerprint=clean(item.seller_or_vin_fingerprint);
  if(seen.has(u)||fingerprints.has(fingerprint)){error='duplicate listing or cross-channel fingerprint';break}
  seen.add(u);fingerprints.add(fingerprint);prices.push(item.price_krw);
 }
 if(error){reject(id,error);continue}
 const avg=Math.round(prices.reduce((a,b)=>a+b,0)/prices.length);
 const grade=prices.length>=10?'A':'B';
 const digest=crypto.createHash('sha256').update(JSON.stringify(r)).digest('hex');
 report.approved.push({candidate_id:id,generation_id,model_year,trim_id,trim_name,powertrain_name,original_price_krw,original_source_url,observed_on,sample_size:prices.length,avg_price_krw:avg,grade,source_urls:listings.map(x=>x.url),dedupe_verified:true,trim_matched:true,evidence_sha256:digest,cohort:c});
}
fs.writeFileSync(result,JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify({checked:report.checked,eligible:report.approved.length,held:report.held.length,report:result}));
