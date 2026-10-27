'use strict';
const crypto=require('node:crypto');
// Bind approval to the exact validated input and each directly fetched original.
function isReviewed(a,r,audit){
 if(!r||!audit||!a.cohort||!Array.isArray(r.listings)||!Array.isArray(audit.originals))return false;
 if(crypto.createHash('sha256').update(JSON.stringify(r)).digest('hex')!==a.evidence_sha256)return false;
 const fields=['generation_id','model_year','trim_id','trim_name','powertrain_name','original_price_krw','original_source_url','observed_on'];
 if(fields.some(k=>a[k]!==r[k])||JSON.stringify(a.cohort)!==JSON.stringify(r.cohort)||a.sample_size!==r.listings.length||a.sample_size<5||a.sample_size>100||!r.listings.every(x=>Number.isSafeInteger(x.price_krw)&&x.price_krw>0)||a.avg_price_krw!==Math.round(r.listings.reduce((sum,x)=>sum+x.price_krw,0)/a.sample_size)||a.grade!==(a.sample_size>=10?'A':'B')||JSON.stringify(a.source_urls)!==JSON.stringify(r.listings.map(x=>x.url))||a.dedupe_verified!==true||a.trim_matched!==true)return false;
 const review=r.independent_source_review;
 return audit.originals.length===a.sample_size && audit.originals.every((doc,i)=>{
  const item=r.listings[i];
  return item&&doc.year_trim_price_confirmed===true&&doc.condition_mileage_confirmed===true&&doc.current_sale_confirmed===true&&doc.url===item.url&&doc.original_content_sha256===item.original_content_sha256&&doc.observed_on===a.observed_on;
 })&&review?.status==='approved'&&review.original_content_verified===true&&review.cross_channel_dedupe_verified===true&&/^https:\/\/[^ ]+/.test(String(review.evidence_report_url||''))&&String(review.reviewer||'').trim().length>=3;
}
module.exports={isReviewed};
