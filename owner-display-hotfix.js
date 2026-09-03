/* CarRanking owner display hotfix v1 */
(()=>{
'use strict';
const C=window.CARRANKING_CONFIG||{},BASE=String(C.supabaseUrl||'').replace(/\/+$/,''),KEY=C.supabasePublishableKey||'';
const H={apikey:KEY,Authorization:`Bearer ${KEY}`};
const esc=s=>String(s??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));
async function get(view,q='select=*'){const r=await fetch(`${BASE}/rest/v1/${view}?${q}`,{headers:H,cache:'no-store'});if(!r.ok)throw new Error(view+' '+r.status);return r.json()}
function card(r,i){return `<article class="owner-rank-card" data-gid="${esc(r.generation_id)}"><b>#${i+1}</b><div><strong>${esc(r.brand)} ${esc(r.model)}</strong><span>${esc(r.generation_code||r.generation||'')} · ${Number(r.rating_count||0)}명 실제 평가</span></div><em>${Number(r.overall_score||0).toFixed(1)}</em></article>`}
function review(r){return `<article class="review-card"><div><strong>${esc([r.brand,r.model,r.generation_code||r.generation].filter(Boolean).join(' '))}</strong><span>${esc(r.display_name||'익명 오너')} · ${new Date(r.created_at).toLocaleDateString('ko-KR')}</span></div>${r.title?`<h4>${esc(r.title)}</h4>`:''}<p>${esc(r.body||'')}</p></article>`}
async function refreshOwnerDisplay(){
 try{
  const [ratings,ranking,reviews]=await Promise.all([
   get('web_rating_summary','select=*&order=overall_score.desc'),
   get('web_owner_ranking','select=*&order=overall_score.desc'),
   get('web_review_feed','select=*&order=created_at.desc&limit=40')
  ]);
  const sum=ratings.reduce((s,r)=>s+Number(r.rating_count||0),0);
  const summary=document.getElementById('reviewSummary');
  if(summary)summary.innerHTML=`<strong>누적 실제 오너평가 ${sum.toLocaleString()}건</strong><span>실제 등록 평점만 오너랭킹에 반영됩니다.</span>`;
  const rank=document.getElementById('ownerRankingList');
  if(rank)rank.innerHTML=ranking.length?ranking.map(card).join(''):'<div class="empty"><strong>아직 실제 오너랭킹 데이터가 없습니다.</strong><p>첫 오너평가가 등록되면 자동으로 순위가 생성됩니다.</p></div>';
  const feed=document.getElementById('reviewFeed');
  if(feed){const owners=reviews.filter(x=>!x.is_reference);feed.innerHTML=owners.length?owners.map(review).join(''):'<div class="empty"><strong>첫 오너 리뷰를 남겨주세요.</strong><p>아직 공개된 리뷰가 없습니다.</p></div>'}
  window.CR_OWNER_REFRESHED={sum,ranking:ranking.length,reviews:reviews.filter(x=>!x.is_reference).length,ts:Date.now()};
 }catch(e){console.warn('owner display refresh failed',e)}
}
function boot(){refreshOwnerDisplay();[1200,3500,7000].forEach(ms=>setTimeout(refreshOwnerDisplay,ms));window.addEventListener('cr-review-saved',()=>setTimeout(refreshOwnerDisplay,300));document.addEventListener('visibilitychange',()=>{if(!document.hidden)refreshOwnerDisplay()});}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',boot,{once:true});else boot();
})();
