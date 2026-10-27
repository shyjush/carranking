'use strict';
const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path');
const {JSDOM}=require(process.env.JSDOM_PATH||'/tmp/carranking-tools-qa/node_modules/jsdom');
const root=path.join(__dirname,'..'),dir=path.join(root,'research/car-bulk-20261027');
const read=n=>JSON.parse(fs.readFileSync(path.join(dir,n),'utf8'));
const powers=read('before-powertrains.json'),specs=read('before-specs.json');
for(const r of read('approved-variants.json')){powers.push({id:r.powertrain_id,generation_id:r.generation_id,name:r.name,fuel_type:r.fuel_type,displacement_cc:r.displacement_cc});specs.push({id:r.spec_id,generation_id:r.generation_id,powertrain_id:r.powertrain_id,combined_efficiency:r.efficiency,source_url:r.source_url,verified_at:'2026-10-27'});}
if(process.env.FOLLOWUP_FIXTURE){specs.push(...JSON.parse(fs.readFileSync(path.join(root,'research/followup-20261027/approved-manufacturer-specs.json'),'utf8')));}
const manufacturers=new Map(read('before-manufacturers.json').map(x=>[x.id,x.name])),models=new Map(read('before-models.json').map(x=>[x.id,x]));
const vehicles=read('before-generations.json').map(g=>{const m=models.get(g.car_model_id);return {generation_id:g.id,brand:manufacturers.get(m.manufacturer_id),model:m.name,generation:g.name,generation_code:g.generation_code};});
const tables={web_search_index:vehicles,vehicle_specs:specs,powertrains:powers,trims:read('before-trims.json'),official_fuel_prices:[]};
const wait=()=>new Promise(r=>setTimeout(r,5));
(async()=>{
 const html=fs.readFileSync(path.join(root,'vehicle-tools.html'),'utf8');
 const dom=new JSDOM(html,{url:'https://carranking.kr/vehicle-tools.html',runScripts:'outside-only'}),w=dom.window,d=w.document;
 w.CARRANKING_CONFIG={useSupabase:true,supabaseUrl:'https://ikhyadzboorscjwcrhcz.supabase.co',supabasePublishableKey:'test-public'};
 const calls=[];w.fetch=async(url,opts)=>{calls.push({url,opts});const u=new URL(url),table=u.pathname.split('/').pop();assert(Object.hasOwn(tables,table));const offset=Number(u.searchParams.get('offset'));return {ok:true,json:async()=>tables[table].slice(offset,offset+1000)};};
 for(const p of ['car-cost-core.js','vehicle-tools.js'])w.eval(fs.readFileSync(path.join(root,p),'utf8'));
 for(let i=0;i<100&&d.querySelector('#model0').disabled;i++)await wait();
 assert.match(d.querySelector('#loadStatus').textContent,new RegExp('179개 세대.*'+(process.env.FOLLOWUP_FIXTURE?'410':'348')+'건'));
 assert.equal(d.querySelector('#spec0').options.length,1,'No representative specification selected silently');
 const change=(id,value,event='change')=>{const e=d.getElementById(id);e.value=value;e.dispatchEvent(new w.Event(event,{bubbles:true}));};
 const k5=vehicles.find(x=>x.model==='K5'&&x.generation_code==='DL3');
 change('model0',k5.generation_id);assert.equal(d.querySelector('#spec0').value,'');d.querySelector('#calculate').click();assert.match(d.querySelector('#inputError').textContent,/직접 선택/);
 let opts=[...d.querySelector('#spec0').options].slice(1);assert.equal(opts.length,28);
 change('spec0',opts[0].value);change('model1',k5.generation_id);change('spec1',opts[1].value);
 assert.equal(d.querySelectorAll('.result').length,2);assert.match(d.querySelector('.summary').textContent,/선택한 2개 사양/);
 assert.match(d.querySelector('#results').textContent,/미입력·합계 제외/);assert.match(d.querySelector('#results').textContent,/공식 인증자료/);assert.match(d.querySelector('#results').textContent,/2026-10-27/);
 const base=Number(d.querySelector('.result .amount').textContent.replace(/\D/g,''));change('insurance0','800000','input');const insurance=Number(d.querySelector('.result .amount').textContent.replace(/\D/g,''));assert.equal(insurance-base,800000);
 change('km','-1','input');assert.match(d.querySelector('#inputError').textContent,/주행거리/);assert.equal(d.querySelectorAll('.result').length,0);
 change('km','0','input');assert.equal(d.querySelector('#inputError').textContent,'');
 change('modelSearch','존재하지않는차량','input');assert.equal(d.querySelector('#model0').value,k5.generation_id,'Filtering must preserve a selected model');assert.equal(d.querySelector('#spec0').value,opts[0].value);
 d.querySelector('#reset').click();assert.equal(d.querySelector('#model0').value,'');assert.equal(d.querySelector('#km').value,'15000');assert.equal(d.querySelector('#insurance0').value,'');
 assert(calls.every(x=>!x.opts.method||x.opts.method==='GET'),'No data writes or personal cost uploads');assert(!calls.some(x=>/ratings|reviews|profiles|cron/.test(x.url)));
 const ids=[...d.querySelectorAll('[id]')].map(x=>x.id);assert.equal(new Set(ids).size,ids.length);
 dom.window.close();console.log('PASS complete 179-generation fixture: explicit selection, two same-model variants, evidence, cost edits, invalid inputs, reset, filter preservation and read-only API access');
})();
