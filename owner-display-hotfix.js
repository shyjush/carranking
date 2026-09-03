/* CarRanking owner display hotfix v2 */
(()=>{
'use strict';
const C=window.CARRANKING_CONFIG||{},BASE=String(C.supabaseUrl||'').replace(/\/+$/,''),KEY=C.supabasePublishableKey||'';
const H={apikey:KEY,Authorization:`Bearer ${KEY}`,'Cache-Control':'no-cache'};
const esc=s=>String(s??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));
async function get(view,q='select=*'){
 const sep=q.includes('?')?'&':'&';
 const r=await fetch(`${BASE}/rest/v1/${view}?${q}${sep}_=${Date.now()}`,{headers:H,cache:'no-store'});
 if(!r.ok){const t=await r.text();throw new Error(`${view} ${r.status} ${t}`)}
 return r.json();
}
function card(r,i){return `<article class="owner-rank-card" data-gid="${esc(r.generation_id)}"><b>#${i+1}</b><div><strong>${esc(r.brand)} ${esc(r.model)}</strong><span>${esc(r.generation_code||r.generation||'')} · ${Number(r.rating_count||0)}명 실제 평가</span></div><em>${Number(r.overall_score||0).toFixed(1)}</em></article>`}
function review(r){return `<article class="review-card"><div><strong>${esc([r.brand,r.model,r.generation_code||r.generation].filter(Boolean).join(' '))}</strong><span>${esc(r.display_name||'익명 오너')} · ${new Date(r.created_at).toLocaleDateString('ko-KR')}</span></div>${r.title?`<h4>${esc(r.title)}</h4>`:''}<p>${esc(r.body||'')}</p></article>`}
async function refreshRatings(){
 try{
  const ratings=await get('web_rating_summary','select=*&order=overall_score.desc');
  const sum=ratings.reduce((s,r)=>s+Number(r.rating_count||0),0);
  const summary=document.getElementById('reviewSummary');
  if(summary)summary.innerHTML=`<strong>누적 실제 오너평가 ${sum.toLocaleString()}건</strong><span>실제 등록 평점만 오너랭킹에 반영됩니다.</span>`;
  return sum;
 }catch(e){console.warn('rating summary refresh failed',e);return null}
}
async function refreshRanking(){
 try{
  const ranking=await get('web_owner_ranking','select=*&order=overall_score.desc');
  const rank=document.getElementById('ownerRankingList');
  if(rank)rank.innerHTML=ranking.length?ranking.map(card).join(''):'<div class="empty"><strong>아직 실제 오너랭킹 데이터가 없습니다.</strong><p>첫 오너평가가 등록되면 자동으로 순위가 생성됩니다.</p></div>';
  return ranking.length;
 }catch(e){console.warn('owner ranking refresh failed',e);return null}
}
async function refreshReviews(){
 try{
  const reviews=await get('web_review_feed','select=*&order=created_at.desc&limit=40');
  const owners=reviews.filter(x=>!x.is_reference);
  const feed=document.getElementById('reviewFeed');
  if(feed)feed.innerHTML=owners.length?owners.map(review).join(''):'<div class="empty"><strong>첫 오너 리뷰를 남겨주세요.</strong><p>아직 공개된 리뷰가 없습니다.</p></div>';
  return owners.length;
 }catch(e){console.warn('owner reviews refresh failed',e);return null}
}
async function refreshOwnerDisplay(){
 const [sum,ranking,reviews]=await Promise.all([refreshRatings(),refreshRanking(),refreshReviews()]);
 window.CR_OWNER_REFRESHED={sum,ranking,reviews,ts:Date.now()};
}
function boot(){
 refreshOwnerDisplay();
 [700,1800,4500,9000].forEach(ms=>setTimeout(refreshOwnerDisplay,ms));
 setInterval(refreshOwnerDisplay,30000);
 window.addEventListener('cr-review-saved',()=>setTimeout(refreshOwnerDisplay,250));
 document.addEventListener('visibilitychange',()=>{if(!document.hidden)refreshOwnerDisplay()});
 window.addEventListener('pageshow',refreshOwnerDisplay);
}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',boot,{once:true});else boot();
})();
