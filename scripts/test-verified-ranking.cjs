'use strict';
const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const source=fs.readFileSync('app.js','utf8');
assert(!source.includes('FALLBACK_DATA')&&!source.includes('ensureTop5'),'Synthetic rank fallback detected');
const extracted=source.match(/function isRankSupported\([\s\S]*?(?=function fillRankingFilters)/);
assert(extracted,'Source-validation function missing');
const verify=vm.runInNewContext(extracted[0]+'\nisRankSupported');
const m={brand:'기아',model:'테스트',generation_code:'XYZ',model_year:2022,original_price_krw:30000000,used_price_krw:22000000,as_of_date:'2026-10-13',sample_size:8,confidence:'B'};
const v=[{brand:'기아',model:'테스트',generation_code:'XYZ',generation_id:'gid'}],p=[{id:'pid',generation_id:'gid'}],t=[{id:'tid',powertrain_id:'pid',model_year:2022,price_krw:30000000,source_url:'https://kia.com/price'}];
const s={generation_id:'gid',model_year:2022,as_of_date:'2026-10-13',listing_count:8,avg_price_krw:22000000,confidence:'B',source_url:'https://example.com/listings',source_name:'verified sample',note:'dedupe_verified=true;trim_matched=true;trim_id=tid'};
assert(verify(m,v,[s],t,p),'Fully evidenced exact trim should qualify');
for(const patch of [{confidence:'C'},{source_url:null},{listing_count:0},{avg_price_krw:21000000},{as_of_date:'2026-10-12'},{note:'trim_matched=true;trim_id=tid'},{note:'dedupe_verified=true;trim_id=tid'},{note:'dedupe_verified=true;trim_matched=true;trim_id=bad'}])
 assert(!verify(m,v,[{...s,...patch}],t,p),'Invalid or unmatched evidence must remain held');
assert(!verify({...m,sample_size:0},v,[s],t,p));
assert(!verify(m,v,[s],[],p));
console.log('PASS verified-only CarRanking rank gate');

const annual=fs.readFileSync('home-fixes.js','utf8'),selectors=fs.readFileSync('vehicle-selector-hotfix.js','utf8'),expansion=fs.readFileSync('ranking-brand-expansion.js','utf8');
assert(annual.includes('CARRANKING_VERIFIED_READY')&&annual.includes('CARRANKING_VERIFIED_RANKING'),'Annual best/worst must share verified source');
assert(selectors.includes('CARRANKING_VERIFIED_RANKING')&&!selectors.includes('const retention=v.retention_rate'),'Selector must not expose legacy metrics');
assert(expansion.includes('CARRANKING_VERIFIED_RANKING'),'Brand ranking extension must share verified data gate');
