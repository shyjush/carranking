(()=>{
'use strict';
const C=window.CARRANKING_CONFIG||{};
const BASE=String(C.supabaseUrl||'').replace(/\/+$/,'');
const KEY=C.supabasePublishableKey||'';
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const pct=v=>v==null?'—':`${(Number(v)*100).toFixed(1)}%`;

function injectCss(){
  if(document.querySelector('link[data-cr-home-fixes]'))return;
  const l=document.createElement('link');
  l.rel='stylesheet'; l.href='home-fixes.css?v=4'; l.dataset.crHomeFixes='1';
  document.head.appendChild(l);
}

async function loadTop5(){
  if(!BASE||!KEY)throw new Error('Supabase config missing');
  const q='select=rank,brand,model,generation,generation_code,category,model_year,retention_rate,depreciation_rate,sample_size,confidence&order=retention_rate.desc&limit=5';
  const r=await fetch(`${BASE}/rest/v1/web_value_ranking?${q}`,{
    headers:{apikey:KEY,Authorization:`Bearer ${KEY}`},
    cache:'no-store'
  });
  if(!r.ok)throw new Error(`web_value_ranking HTTP ${r.status}`);
  return r.json();
}

function renderTop5(rows){
  const ranking=document.getElementById('ranking');
  if(!ranking)return;
  let sec=document.getElementById('editorialPreview');
  if(!sec){
    sec=document.createElement('section');
    sec.id='editorialPreview';
    sec.className='section editorial-preview-section';
    ranking.insertAdjacentElement('afterend',sec);
  }
  const cards=(rows||[]).slice(0,5).map((v,i)=>{
    const gen=v.generation_code||v.generation||'';
    return `<article class="editorial-mini-card live-value-card">
      <div class="editorial-mini-head"><strong>#${i+1} ${esc(v.brand)} ${esc(v.model)} · ${esc(v.model_year||'-')}</strong><span>${esc(v.confidence||'')}등급</span></div>
      <h3>가치보존율 ${pct(v.retention_rate)}</h3>
      <p>${esc(gen)}${v.category?` · ${esc(v.category)}`:''}<br>감가율 ${pct(v.depreciation_rate)} · 표본 ${esc(v.sample_size??'미확보')}대</p>
      <small>CarRanking 가치보존 데이터 · Supabase 자동 업데이트</small>
    </article>`;
  }).join('');
  sec.innerHTML=`<div class="section-head"><div><p class="eyebrow">LIVE VALUE RETENTION TOP5</p><h2>현재 가치보존 TOP5</h2><p class="muted-dark">CarRanking DB의 A·B등급 가치보존 순위를 실시간으로 반영합니다. 신차가·중고시세 데이터가 갱신되면 이 영역도 자동 변경됩니다.</p></div></div><div class="editorial-review-grid">${cards||'<div class="empty">가치보존 데이터를 불러오는 중입니다.</div>'}</div>`;
}

function showError(){
  const ranking=document.getElementById('ranking'); if(!ranking)return;
  let sec=document.getElementById('editorialPreview');
  if(!sec){sec=document.createElement('section');sec.id='editorialPreview';sec.className='section editorial-preview-section';ranking.insertAdjacentElement('afterend',sec)}
  sec.innerHTML='<div class="section-head"><div><p class="eyebrow">LIVE VALUE RETENTION TOP5</p><h2>현재 가치보존 TOP5</h2><p class="muted-dark">실시간 데이터를 불러오지 못했습니다. 잠시 후 다시 확인해 주세요.</p></div></div>';
}

async function run(){
  injectCss();
  const old=document.getElementById('editorialPreview');
  if(old)old.remove();
  try{renderTop5(await loadTop5())}catch(e){console.warn('Live TOP5 load failed',e);showError()}
}

if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',run,{once:true});else run();
})();
