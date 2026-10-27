'use strict';
const assert=require('node:assert/strict'),fs=require('node:fs'),C=require('../car-cost-core.js');
const dir='research/followup-20261027/',read=n=>JSON.parse(fs.readFileSync(dir+n));
const ps=new Map(read('before-powertrains.json').map(p=>[p.id,p])),rows=read('approved-manufacturer-specs.json');
assert.equal(rows.length,62);const matched=new Set();
for(const r of rows){const p=ps.get(r.powertrain_id),v=C.variant(r,p);assert(v,JSON.stringify(r));matched.add(p.id);assert(v.specificationLabel.includes('인치'));assert.equal(v.certificationYear,null);assert(!/20\d{2}년 인증/.test(v.specificationLabel));assert.equal(v.unit==='ev',p.fuel_type==='전기');if(p.fuel_type==='전기')assert(v.specificationLabel.includes(p.battery_kwh+'kWh'));}
assert.equal(matched.size,20);
const ev9=rows.filter(r=>r.source_url.includes('/ev9/'));assert.equal(ev9.length,10);assert(ev9.every(r=>/[67]인승/.test(r.combined_efficiency)));
const carnival=rows.filter(r=>r.source_url.includes('/carnival/'));assert.equal(carnival.length,6);assert(carnival.every(r=>!r.combined_efficiency.startsWith('8.7 ')),'High-roof rows must not enter ordinary-body plan');
assert(!rows.some(r=>r.source_url.includes('/ev4/')&&/스탠다드.*19인치/.test(r.combined_efficiency)),'Contradictory official 4WD heading must be held');
const seltos=rows.filter(r=>r.source_url.includes('seltos'));assert.equal(seltos.length,5);assert(seltos.every(r=>r.source_url.endsWith('.pdf')&&r.combined_efficiency.includes('SP2')));
const price=read('original-price-evidence.json'),ds=new Map(read('before-depreciation.json').map(d=>[d.id,d]));assert.equal(price.length,5);for(const x of price)assert.equal(x.price_krw,ds.get(x.depreciation_id).original_price_krw);
console.log('PASS 62 exact manufacturer variants, all 20 missing powers, EV battery/units, seating, source conflict/high-roof exclusions and 5 partial price sources');
