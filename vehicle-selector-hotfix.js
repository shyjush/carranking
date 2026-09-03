/* CarRanking selector reliability hotfix v2
   Keeps vehicle/brand/model selectors and score action usable even when optional APIs fail. */
(()=>{
'use strict';
const C=window.CARRANKING_CONFIG||{};
const BASE=String(C.supabaseUrl||'').replace(/\/+$/,'');
const KEY=C.supabasePublishableKey||'';
let rows=[];
const esc=s=>String(s??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));
const label=v=>[v.brand,v.model,v.generation_code||v.generation].filter(Boolean).join(' ');
const pct=v=>v==null?'정보 없음':`${(Number(v)*100).toFixed(1)}%`;
async function getVehicles(){
  if(!BASE||!KEY)return [];
  const qs='select=*&order=brand.asc,model.asc,start_year.desc';
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
async function getRating(gid){
  if(!BASE||!KEY||!gid)return null;
  try{
    const r=await fetch(`${BASE}/rest/v1/web_rating_summary?select=*&generation_id=eq.${encodeURIComponent(gid)}&limit=1`,{headers:{apikey:KEY}});
    if(!r.ok)return null;const data=await r.json();return data[0]||null;
  }catch(_){return null}
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
async function showScoreHotfix(){
  const sel=document.getElementById('scoreVehicle'),out=document.getElementById('scoreResult');
  const id=sel?.value||'';
  const v=rows.find(x=>String(x.generation_id)===String(id));
  if(!v){if(out)out.innerHTML='<p class="notice">차량을 선택해 주세요.</p>';return}
  if(out)out.innerHTML='<p class="notice">점수를 불러오는 중입니다.</p>';
  const r=await getRating(id);
  const retention=v.retention_rate!=null?pct(v.retention_rate):'정보 없음';
  const rating=r&&Number.isFinite(Number(r.overall_score))?`${Number(r.overall_score).toFixed(1)} / 10 (${Number(r.rating_count||0)}명)`:'평가 데이터 부족';
  if(out)out.innerHTML=`<div class="score-summary"><strong>${esc(label(v))}</strong><span>가치보존율 ${esc(retention)}</span><span>오너 종합평점 ${esc(rating)}</span>${r?`<span>신뢰성 ${Number(r.reliability||0).toFixed(1)} · 승차감 ${Number(r.ride_comfort||0).toFixed(1)} · 재구매 ${Number(r.repurchase_intent||0).toFixed(1)}</span>`:''}</div>`;
}
function bindScoreButton(){
  const btn=document.getElementById('scoreBtn');if(!btn||btn.dataset.crScoreHotfix)return;
  btn.dataset.crScoreHotfix='1';
  btn.addEventListener('click',e=>{e.preventDefault();e.stopImmediatePropagation();showScoreHotfix()},true);
}
async function repair(){
  enableNativeSelects();
  if(!rows.length)rows=await getVehicles();
  if(!rows.length){console.warn('CarRanking selector hotfix: vehicle data unavailable');return;}
  fillAllVehicleSelects();fillScoreBrands();enableNativeSelects();bindScoreButton();
  window.CR_VEHICLE_SELECTOR_ROWS=rows;
}
function boot(){repair();[700,1600,3200].forEach(ms=>setTimeout(repair,ms))}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',boot,{once:true});else boot();
})();
