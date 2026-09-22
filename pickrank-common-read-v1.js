/* PICKRANK read-only canonical common data; CarRanking value/owner rankings stay local */
(()=>{'use strict';
const FEED='https://umreaxukykowauxkauyd.supabase.co/functions/v1/canonical-feed?category=car&limit=500';
const norm=v=>String(v||'').replace(/\s+/g,'').replace(/^the/i,'').toLowerCase();
async function apply(){
 try{
  const r=await fetch(FEED,{cache:'no-store'}); if(!r.ok)throw new Error('canonical feed '+r.status);
  const j=await r.json(),records=Array.isArray(j.records)?j.records:[]; if(!records.length)return;
  let changed=0;
  for(const rec of records){
   const p=rec.payload||{},brand=p.manufacturer||'',model=p.model||rec.name||'';
   const v=Array.isArray(VEHICLES)&&VEHICLES.find(x=>(!brand||norm(x.brand)===norm(brand))&&norm(x.model)===norm(model));
   if(!v)continue;
   v.brand=brand||v.brand;
   v.model=p.model||v.model;
   v.trim_price_krw=p.starting_price_krw||v.trim_price_krw;
   v.trim_model_year=p.model_year||v.trim_model_year;
   v.powertrain_name=p.powertrain||v.powertrain_name;
   v.common_verified_at=p.as_of_date||p.verified_on||rec.updated_at||v.common_verified_at;
   v.pickrank_canonical_key=rec.canonical_key;
   v.pickrank_version=rec.version;
   changed++;
  }
  if(changed){fillVehicleSelectors();renderRanking();renderHero();document.documentElement.dataset.pickrankCommon='active';}
 }catch(e){console.warn('[CarRanking] canonical common-data fallback',e);}
}
const start=()=>setTimeout(apply,1400);
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',start,{once:true});else start();
})();