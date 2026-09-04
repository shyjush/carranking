/* CarRanking live ranking sync: DB is the source of truth */
(()=>{'use strict';
const esc=s=>String(s??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));
const pct=v=>v==null?'정보 없음':`${(Number(v)*100).toFixed(1)}%`;
async function load(){
 const C=window.CARRANKING_CONFIG||{};
 const base=String(C.supabaseUrl||'').replace(/\/+$/,''), key=C.supabasePublishableKey||'';
 const body=document.getElementById('rankingBody'), hero=document.getElementById('heroCard');
 if(!base||!key||!body)return;
 try{
  const r=await fetch(`${base}/rest/v1/web_value_ranking?select=*&order=retention_rate.desc`,{headers:{apikey:key},cache:'no-store'});
  if(!r.ok)throw new Error(`ranking HTTP ${r.status}`);
  const rows=await r.json(); if(!Array.isArray(rows)||!rows.length)return;
  window.CR_LIVE_RANKING=rows;
  window.CR_LIVE_RANKING_COUNT=rows.length;
  body.innerHTML=rows.map((x,i)=>`<tr><td><strong>#${x.rank??i+1}</strong></td><td><strong>${esc(x.brand)} ${esc(x.model)}</strong><span class="muted-dark small">${esc(x.generation_code||x.generation||'')}</span></td><td>${esc(x.model_year??'-')}</td><td><span class="badge">${pct(x.retention_rate)}</span></td><td>${pct(x.depreciation_rate)}</td><td>${esc(x.sample_size??'미확보')}</td></tr>`).join('');
  const top=rows[0];
  if(hero&&top)hero.innerHTML=`<div class="metric-label">가치보존율 1위</div><div class="car-name">${esc(top.brand)} ${esc(top.model)} ${esc(top.generation_code||top.generation||'')}</div><div class="big">${pct(top.retention_rate)}</div><div class="muted">${esc(top.model_year??'-')}년식 · 실시간 DB 기준</div>`;
  document.documentElement.dataset.rankingRows=String(rows.length);
 }catch(e){console.warn('live ranking sync',e)}
}
function start(){load();setInterval(load,120000)}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',()=>setTimeout(start,1200),{once:true});else setTimeout(start,1200);
})();
