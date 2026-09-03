/* CarRanking owner display hotfix v6 */
(()=>{
'use strict';
if(window.__CR_OWNER_V6__)return;window.__CR_OWNER_V6__=true;
const C=window.CARRANKING_CONFIG||{},BASE=String(C.supabaseUrl||'').replace(/\/+$/,''),KEY=C.supabasePublishableKey||'';
const H={apikey:KEY,'Content-Type':'application/json','Cache-Control':'no-cache','Pragma':'no-cache'};
const esc=s=>String(s??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));
let last=null,painting=false;
function card(r,i){return `<article class="owner-rank-card" data-cr-owner-v6="1" data-gid="${esc(r.generation_id)}"><b>#${i+1}</b><div><strong>${esc(r.brand)} ${esc(r.model)}</strong><span>${esc(r.generation_code||r.generation||'')} · ${Number(r.rating_count||0)}명 실제 평가</span></div><em>${Number(r.overall_score||0).toFixed(1)}</em></article>`}
function review(r){return `<article class="review-card" data-cr-owner-v6="1"><div><strong>${esc([r.brand,r.model,r.generation_code||r.generation].filter(Boolean).join(' '))}</strong><span>${esc(r.display_name||'익명 오너')} · ${new Date(r.created_at).toLocaleDateString('ko-KR')}</span></div>${r.title?`<h4>${esc(r.title)}</h4>`:''}<p>${esc(r.body||'')}</p></article>`}
async function dashboard(){const r=await fetch(`${BASE}/rest/v1/rpc/get_public_owner_dashboard`,{method:'POST',headers:H,body:'{}',cache:'no-store'});const t=await r.text();if(!r.ok)throw new Error(`owner dashboard ${r.status} ${t}`);return t?JSON.parse(t):{}}
function paint(d){
 painting=true;
 try{
  const ranking=Array.isArray(d?.ranking)?d.ranking:[],reviews=Array.isArray(d?.reviews)?d.reviews:[],sum=Number(d?.rating_count||0);
  const summary=document.getElementById('reviewSummary');if(summary){summary.dataset.crOwnerV6='1';summary.innerHTML=`<strong>누적 실제 오너평가 ${sum.toLocaleString()}건</strong><span>실제 등록 평점만 오너랭킹에 반영됩니다.</span>`}
  const rank=document.getElementById('ownerRankingList');if(rank){rank.dataset.crOwnerV6='1';rank.innerHTML=ranking.length?ranking.map(card).join(''):'<div class="empty" data-cr-owner-v6="1"><strong>아직 실제 오너랭킹 데이터가 없습니다.</strong><p>첫 오너평가가 등록되면 자동으로 순위가 생성됩니다.</p></div>'}
  const feed=document.getElementById('reviewFeed');if(feed){feed.dataset.crOwnerV6='1';feed.innerHTML=reviews.length?reviews.map(review).join(''):'<div class="empty" data-cr-owner-v6="1"><strong>첫 오너 리뷰를 남겨주세요.</strong><p>아직 공개된 리뷰가 없습니다.</p></div>'}
  window.CR_OWNER_REFRESHED={sum,ranking:ranking.length,reviews:reviews.length,ts:Date.now(),version:6};
 }finally{painting=false}
}
async function refresh(){try{last=await dashboard();paint(last)}catch(e){console.warn('owner dashboard refresh failed',e)}}
function guard(){
 const feed=document.getElementById('reviewFeed'),rank=document.getElementById('ownerRankingList'),summary=document.getElementById('reviewSummary');
 [feed,rank,summary].filter(Boolean).forEach(el=>new MutationObserver(()=>{if(!painting&&last)queueMicrotask(()=>paint(last))}).observe(el,{childList:true,subtree:true,characterData:true}));
}
function boot(){guard();refresh();[300,900,1800,3500,7000,12000].forEach(ms=>setTimeout(refresh,ms));setInterval(()=>{if(last)paint(last)},2000);setInterval(refresh,30000);window.addEventListener('cr-review-saved',()=>setTimeout(refresh,120));document.addEventListener('visibilitychange',()=>{if(!document.hidden)refresh()});window.addEventListener('pageshow',refresh)}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',boot,{once:true});else boot();
})();
