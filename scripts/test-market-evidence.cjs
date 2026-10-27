'use strict';
// Synthetic fixtures only; never write fixtures to production or evidence inbox.
const assert=require('node:assert/strict'),fs=require('node:fs'),os=require('node:os'),path=require('node:path'),cp=require('node:child_process'),{isReviewed}=require('./market-evidence-review.cjs');
const tmp=fs.mkdtempSync(path.join(os.tmpdir(),'carranking-evidence-test-'));
const d='2020-01-02',gid='00000000-0000-4000-8000-000000000001';
const cohort={drivetrain:'2WD',transmission:'CVT',option_basis:'base, no paid options',accident_status:'no_accident',mileage_min_km:40000,mileage_max_km:60000};
const base={candidate_id:'synthetic-test-only',generation_id:gid,model_year:2021,trim_id:'00000000-0000-4000-8000-000000000002',trim_name:'Synthetic trim',powertrain_name:'Synthetic powertrain',original_price_krw:10000000,original_source_url:'https://fixture.invalid/original',observed_on:d,source_permission:'public-permitted',cohort,independent_source_review:{status:'approved',original_content_verified:true,cross_channel_dedupe_verified:true,evidence_report_url:'https://fixture.invalid/review',reviewer:'synthetic test'},listings:Array.from({length:5},(_,i)=>({url:'https://fixture.invalid/listing/'+i,observed_on:d,price_krw:5000000+i*10000,model_year:2021,trim_name:'Synthetic trim',powertrain_name:'Synthetic powertrain',generation_id:gid,listing_id:String(i),seller_or_vin_fingerprint:'test-only-'+i,listing_status:'for_sale',observation_source:'direct_original',original_content_sha256:String(i).repeat(64),condition_source_url:'https://fixture.invalid/condition/'+i,mileage_km:50000,...cohort}))};
function run(edit){const r=structuredClone(base);if(edit)edit(r);fs.writeFileSync(path.join(tmp,'input.json'),JSON.stringify([r]));const x=cp.spawnSync(process.execPath,[path.resolve(__dirname,'validate-market-evidence.cjs'),path.join(tmp,'input.json'),path.join(tmp,'output.json')],{cwd:tmp,encoding:'utf8'});assert.equal(x.status,0,x.stderr);return {r,report:JSON.parse(fs.readFileSync(path.join(tmp,'output.json'),'utf8'))};}
try{
 const good=run();assert.equal(good.report.approved.length,1);
 for(const edit of [r=>delete r.cohort,r=>delete r.listings[0].mileage_km,r=>delete r.listings[0].accident_status,r=>r.listings[0].listing_status='sold',r=>r.listings[0].observation_source='search_cache',r=>r.listings[0].drivetrain='AWD',r=>r.listings[0].transmission='manual',r=>r.listings[0].option_basis='added package',r=>r.listings[0].mileage_km=70000,r=>r.listings[0].accident_status='unknown',r=>r.listings[0].original_content_sha256='',r=>r.listings[1].seller_or_vin_fingerprint=r.listings[0].seller_or_vin_fingerprint]) assert.equal(run(edit).report.approved.length,0);
 const a=good.report.approved[0],audit={originals:good.r.listings.map(item=>({year_trim_price_confirmed:true,condition_mileage_confirmed:true,current_sale_confirmed:true,url:item.url,original_content_sha256:item.original_content_sha256,observed_on:d}))};
 assert.equal(isReviewed(a,good.r,audit),true);
 const mutated=structuredClone(good.r);mutated.listings[0].price_krw+=100000;assert.equal(isReviewed(a,mutated,audit),false);
 const tampered=structuredClone(a);tampered.avg_price_krw+=100000;assert.equal(isReviewed(tampered,good.r,audit),false);
 const stale=structuredClone(audit);stale.originals[0].original_content_sha256='f'.repeat(64);assert.equal(isReviewed(a,good.r,stale),false);
 delete stale.originals[0].current_sale_confirmed;assert.equal(isReviewed(a,good.r,stale),false);
 console.log('PASS 12 unsafe cohorts rejected; direct originals, active status, mileage/accident/options, duplicate and review hash checks');
}finally{fs.rmSync(tmp,{recursive:true,force:true});}
