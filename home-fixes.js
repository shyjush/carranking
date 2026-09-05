(()=>{
'use strict';
const C=window.CARRANKING_CONFIG||{};
const BASE=String(C.supabaseUrl||'').replace(/\/+$/,'');
const KEY=C.supabasePublishableKey||'';
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot',"'":'&#39;'}[c]));
const pct=v=>v==null?'—':`${(Number(v)*100).toFixed(1)}%`;
let ANNUAL=[];

function injectCss(){
  if(document.querySelector('link[data-cr-home-fixes]'))return;
  const l=document.createElement('link');
  l.rel='stylesheet'; l.href='home-fixes.css?v=6'; l.dataset.crHomeFixes='1';
  document.head.appendChild(l);
}

async function loadAnnual(){
  if(!BASE||!KEY)throw new Error('Supabase config missing');
  const q='select=rank,brand,model,generation,generation_code,category,model_year,retention_rate,depreciation_rate,annual_retention_rate,annual_depreciation_rate,age_years,sample_size,confidence&order=annual_retention_rate.desc';
  const r=await fetch(`${BASE}/rest/v1/web_annualized_value_ranking?${q}`,{headers:{apikey:KEY,Authorization:`Bearer ${KEY}`},cache:'no-store'});
  if(!r.ok)throw new Error(`web_annualized_value_ranking HTTP ${r.status}`);
  return r.json();
}

function filteredRows(){
  const b=document.getElementById('brandFilter')?.value||'';
  const c=document.getElementById('categoryFilter')?.value||'';
  return ANNUAL.filter(x=>(!b||x.brand===b)&&(!c||x.category===c));
}

function renderHero(){
  const x=ANNUAL[0],hero=document.getElementById('heroCard');
  if(!x||!hero)return;
  hero.innerHTML=`<div class="metric-label">연식 보정 가치보존 1위</div><div class="car-name">${esc(x.brand)} ${esc(x.model)} ${esc(x.generation_code||'')}</div><div class="big">${pct(x.annual_retention_rate)}</div><div class="muted">${esc(x.model_year)}년식 · 현재 가치보존 ${pct(x.retention_rate)}</div>`;
}

function renderMainRanking(){
  const ranking=document.getElementById('ranking');
  const body=document.getElementById('rankingBody');
  if(!ranking||!body||!ANNUAL.length)return;
  const eyebrow=ranking.querySelector('.eyebrow'); if(eyebrow)eyebrow.textContent='AGE-ADJUSTED VALUE RETENTION RANKING';
  const h2=ranking.querySelector('h2'); if(h2)h2.textContent='연식 보정 가치보존 랭킹';
  const th=ranking.querySelectorAll('thead th');
  if(th[3])th[3].textContent='연평균 가치보존율';
  if(th[4])th[4].textContent='연평균 감가율';
  const note=ranking.querySelector('.footnote');
  if(note)note.textContent='※ 동일 연식·세대·파워트레인·트림의 신차가와 중고 실매물 평균을 비교하고, 차량 연령을 연평균 기준으로 보정한 A·B등급 데이터만 순위에 반영합니다.';
  const rows=filteredRows();
  body.innerHTML=rows.map((x,i)=>`<tr class="annual-rank-row"><td><strong>#${x.rank??i+1}</strong></td><td><strong>${esc(x.brand)} ${esc(x.model)}</strong><span class="muted-dark small">${esc(x.generation_code||x.generation||'')}</span></td><td>${esc(x.model_year||'-')}</td><td><span class="badge">${pct(x.annual_retention_rate)}</span><span class="muted-dark small">현재 ${pct(x.retention_rate)}</span></td><td>${pct(x.annual_depreciation_rate)}</td><td>${esc(x.sample_size??'미확보')}</td></tr>`).join('');
  renderHero();
}

function renderBestWorst(){
  const ranking=document.getElementById('ranking'); if(!ranking||!ANNUAL.length)return;
  let sec=document.getElementById('editorialPreview');
  if(!sec){sec=document.createElement('section');sec.id='editorialPreview';sec.className='section editorial-preview-section';ranking.insertAdjacentElement('afterend',sec)}
  const best=ANNUAL.slice(0,10),worst=[...ANNUAL].sort((a,b)=>Number(a.annual_retention_rate)-Number(b.annual_retention_rate)).slice(0,10);
  const cards=(rows,isWorst=false)=>rows.map((v,i)=>`<article class="editorial-mini-card live-value-card"><div class="editorial-mini-head"><strong>#${i+1} ${esc(v.brand)} ${esc(v.model)} · ${esc(v.model_year)}</strong><span>${esc(v.confidence||'')}등급</span></div><h3>연평균 ${pct(v.annual_retention_rate)}</h3><p>${esc(v.generation_code||v.generation||'')}<br>현재 가치보존 ${pct(v.retention_rate)} · 연평균 감가 ${pct(v.annual_depreciation_rate)} · 표본 ${esc(v.sample_size??'미확보')}대</p><small>${isWorst?'연식 보정 WORST 10':'연식 보정 BEST 10'} · Supabase 자동 업데이트</small></article>`).join('');
  sec.innerHTML=`<div class="section-head"><div><p class="eyebrow">AGE-ADJUSTED BEST / WORST</p><h2>연식 보정 BEST 10 · WORST 10</h2><p class="muted-dark">단순히 신차에 가까운 연식이 유리하지 않도록 차량 연령을 보정한 연평균 가치보존율 기준입니다. 기존 현재 가치보존율은 각 카드에 함께 표시합니다.</p></div></div><h3>BEST 10</h3><div class="editorial-review-grid">${cards(best)}</div><h3 style="margin-top:28px">WORST 10</h3><div class="editorial-review-grid">${cards(worst,true)}</div>`;
}

function bindFilters(){
  ['brandFilter','categoryFilter'].forEach(id=>{
    const el=document.getElementById(id); if(!el||el.dataset.annualBound)return;
    el.dataset.annualBound='1'; el.addEventListener('change',()=>setTimeout(renderMainRanking,0));
  });
}

function enforceForStartupRace(){
  [150,500,1000,1800,3000,5000].forEach(ms=>setTimeout(()=>{renderMainRanking();renderHero()},ms));
}

function showError(){
  const ranking=document.getElementById('ranking'); if(!ranking)return;
  let sec=document.getElementById('editorialPreview');
  if(!sec){sec=document.createElement('section');sec.id='editorialPreview';sec.className='section editorial-preview-section';ranking.insertAdjacentElement('afterend',sec)}
  sec.innerHTML='<div class="section-head"><div><p class="eyebrow">AGE-ADJUSTED VALUE RETENTION</p><h2>연식 보정 랭킹</h2><p class="muted-dark">실시간 데이터를 불러오지 못했습니다. 잠시 후 다시 확인해 주세요.</p></div></div>';
}

async function run(){
  injectCss();
  const old=document.getElementById('editorialPreview'); if(old)old.remove();
  try{ANNUAL=await loadAnnual();renderMainRanking();renderBestWorst();bindFilters();enforceForStartupRace()}catch(e){console.warn('Annual ranking load failed',e);showError()}
}

if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',run,{once:true});else run();
})();
