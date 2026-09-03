/* CarRanking selector reliability hotfix v1
   Keeps vehicle/brand/model selectors usable even when an optional homepage API fails. */
(()=>{
'use strict';
const C=window.CARRANKING_CONFIG||{};
const BASE=String(C.supabaseUrl||'').replace(/\/+$/,'');
const KEY=C.supabasePublishableKey||'';
let rows=[];
const esc=s=>String(s??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));
const label=v=>[v.brand,v.model,v.generation_code||v.generation].filter(Boolean).join(' ');
async function getVehicles(){
  if(!BASE||!KEY)return [];
  const qs='select=generation_id,brand,model,generation_code,generation,start_year&order=brand.asc,model.asc,start_year.desc';
  for(const view of ['web_vehicle_detail','web_compare_base']){
    try{
      const r=await fetch(`${BASE}/rest/v1/${view}?${qs}`,{headers:{apikey:KEY}});
      if(!r.ok)continue;
      const data=await r.json();
      if(Array.isArray(data)&&data.length)return data;
    }catch(_){ }
  }
  return [];
}
function optionHtml(v){return `<option value="${esc(v.generation_id)}">${esc(label(v))}</option>`}
function fillAllVehicleSelects(){
  if(!rows.length)return;
  const opts=rows.map(optionHtml).join('');
  const rv=document.getElementById('reviewVehicle');
  if(rv && rv.options.length<=1) rv.innerHTML='<option value="">차량/세대 선택</option>'+opts;
  ['compare1','compare2','compare3'].forEach((id,i)=>{
    const s=document.getElementById(id);if(!s||s.options.length>1)return;
    s.innerHTML=`<option value="">차량 ${i+1} 선택${i===2?' (선택)':''}</option>`+opts;
  });
}
function fillScoreBrands(){
  const b=document.getElementById('scoreBrand');if(!b||!rows.length)return;
  if(b.options.length<=1){
    const brands=[...new Set(rows.map(v=>v.brand).filter(Boolean))].sort((a,z)=>a.localeCompare(z,'ko'));
    b.innerHTML='<option value="">브랜드 선택</option>'+brands.map(x=>`<option value="${esc(x)}">${esc(x)}</option>`).join('');
  }
  fillScoreVehicles();
  if(!b.dataset.crSelectorFix){b.dataset.crSelectorFix='1';b.addEventListener('change',fillScoreVehicles)}
}
function fillScoreVehicles(){
  const b=document.getElementById('scoreBrand'),s=document.getElementById('scoreVehicle');if(!s||!rows.length)return;
  const brand=b?.value||'';
  const list=rows.filter(v=>!brand||v.brand===brand);
  const current=s.value;
  s.innerHTML='<option value="">모델/세대 선택</option>'+list.map(optionHtml).join('');
  if(current && [...s.options].some(o=>o.value===current))s.value=current;
}
function enableNativeSelects(){
  ['reviewVehicle','scoreBrand','scoreVehicle','compare1','compare2','compare3'].forEach(id=>{
    const s=document.getElementById(id);if(s){s.disabled=false;s.removeAttribute('aria-disabled')}
  });
}
async function repair(){
  enableNativeSelects();
  if(!rows.length)rows=await getVehicles();
  if(!rows.length){console.warn('CarRanking selector hotfix: vehicle data unavailable');return;}
  fillAllVehicleSelects();fillScoreBrands();enableNativeSelects();
  window.CR_VEHICLE_SELECTOR_ROWS=rows;
}
function boot(){repair();[700,1600,3200].forEach(ms=>setTimeout(repair,ms))}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',boot,{once:true});else boot();
})();
