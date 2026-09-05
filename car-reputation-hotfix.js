/* CarRanking member review submit ordering hotfix + live value TOP5 sync */
(()=>{
'use strict';
const TOKEN_KEY='carranking_access_token';
// car-reputation.js의 document capture 핸들러가 먼저 회원 RPC를 시작한다.
// 여기서는 같은 capture 단계에서 즉시 기본 submit/기존 app.js submit 전파를 차단해
// 회원 리뷰가 익명 visitor 리뷰로 중복 등록되는 것을 방지한다.
document.addEventListener('submit',e=>{
  if(e.target?.id!=='reviewForm')return;
  if(!localStorage.getItem(TOKEN_KEY))return;
  e.preventDefault();
  e.stopImmediatePropagation();
},true);

// Homepage TOP5 cards: always follow Supabase web_value_ranking.
const esc=s=>String(s??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));
const pct=v=>v==null?'정보 없음':`${(Number(v)*100).toFixed(1)}%`;
async function loadLiveTop5(){
  const C=window.CARRANKING_CONFIG||{};
  if(!C.supabaseUrl||!C.supabasePublishableKey)return [];
  const base=String(C.supabaseUrl).replace(/\/+$/,'');
  const q='select=rank,brand,model,generation,generation_code,category,model_year,retention_rate,depreciation_rate,sample_size,confidence&order=retention_rate.desc&limit=5';
  const r=await fetch(`${base}/rest/v1/web_value_ranking?${q}`,{headers:{apikey:C.supabasePublishableKey,Authorization:`Bearer ${C.supabasePublishableKey}`}});
  if(!r.ok)throw new Error(`web_value_ranking HTTP ${r.status}`);
  return r.json();
}
function renderLiveTop5(rows){
  if(!Array.isArray(rows)||!rows.length)return;
  const ranking=document.getElementById('ranking');
  if(!ranking)return;
  let sec=document.getElementById('editorialPreview')||document.getElementById('liveValueTop5');
  if(!sec){sec=document.createElement('section');sec.id='liveValueTop5';sec.className='section editorial-preview-section';ranking.insertAdjacentElement('afterend',sec)}
  else sec.id='liveValueTop5';
  const cards=rows.map((v,i)=>`<article class="editorial-mini-card live-value-card"><div class="editorial-mini-head"><strong>#${i+1} ${esc(v.brand)} ${esc(v.model)} · ${esc(v.model_year??'-')}</strong><span>${esc(v.confidence||'')}등급</span></div><h3>가치보존율 ${pct(v.retention_rate)}</h3><p>${esc(v.generation_code||v.generation||'')} · 감가율 ${pct(v.depreciation_rate)} · 표본 ${esc(v.sample_size??'미확보')}건</p><small>CarRanking 실시간 가치보존 데이터 · Supabase 자동연동</small></article>`).join('');
  sec.innerHTML=`<div class="section-head"><div><p class="eyebrow">LIVE VALUE RETENTION TOP 5</p><h2>현재 가치보존 TOP5</h2><p class="muted-dark">CarRanking의 A/B 신뢰도 가치보존 데이터를 기준으로 자동 갱신됩니다. DB 순위가 바뀌면 이 영역도 함께 변경됩니다.</p></div></div><div class="editorial-review-grid">${cards}</div>`;
}
async function syncLiveTop5(){try{renderLiveTop5(await loadLiveTop5())}catch(e){console.warn('Live TOP5 sync failed',e)}}
function bootTop5(){syncLiveTop5();setTimeout(syncLiveTop5,700);setTimeout(syncLiveTop5,1800)}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',bootTop5,{once:true});else bootTop5();
})();