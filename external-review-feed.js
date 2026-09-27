/* CarRanking approved external evaluation references v1 */
(()=>{
'use strict';
const C=window.CARRANKING_CONFIG||{};
const BASE=String(C.supabaseUrl||'').replace(/\/+$/,'');
const KEY=C.supabasePublishableKey||'';
const box=document.getElementById('externalReviewFeed');
if(!box||!BASE||!KEY)return;
const esc=s=>String(s??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));
const fmt=d=>d?new Intl.DateTimeFormat('ko-KR',{timeZone:'Asia/Seoul',year:'numeric',month:'numeric',day:'numeric'}).format(new Date(d+'T00:00:00+09:00')):'게시일 미확인';
async function load(){
 try{
  const q='select=brand,model,generation_code,source_type,source_name,title,source_url,published_date,observed_date,author_label,powertrain_hint,trim_hint,summary,source_confidence,dedupe_status&order=published_date.desc.nullslast,observed_date.desc&limit=100';
  const r=await fetch(BASE+'/rest/v1/web_external_review_feed?'+q,{headers:{apikey:KEY,Authorization:'Bearer '+KEY},cache:'no-store'});
  if(!r.ok)throw new Error('HTTP '+r.status);
  const rows=await r.json();
  box.innerHTML=rows.length?rows.map(x=>{
   const label=x.source_type==='expert_road_test'?'전문 시승·계측':'전문 코멘트';
   const car=[x.brand,x.model,x.generation_code].filter(Boolean).join(' ');
   const detail=[x.powertrain_hint,x.trim_hint].filter(Boolean).join(' · ');
   return '<article class="review-card external-reference-card">'
    +'<div><strong>'+esc(car)+'</strong><span>'+esc(label)+' · '+esc(x.source_name)+' · '+esc(x.source_confidence)+'등급</span></div>'
    +'<h4>'+esc(x.title)+'</h4>'
    +'<p>'+esc(x.summary)+'</p>'
    +'<p class="muted-dark small">'+esc(detail)+(detail?' · ':'')+esc(fmt(x.published_date))+' · 확인 '+esc(fmt(x.observed_date))+'</p>'
    +'<div class="actions"><a class="btn" href="'+esc(x.source_url)+'" target="_blank" rel="noopener noreferrer nofollow">원문 확인</a></div>'
    +'</article>';
  }).join(''):'<div class="empty"><strong>승인된 외부평가 자료가 아직 없습니다.</strong></div>';
 }catch(e){
  console.warn('External review feed failed',e);
  box.innerHTML='<div class="empty"><strong>외부평가 자료를 불러오지 못했습니다.</strong><p>CarRanking 내부 오너리뷰와 가치보존 순위에는 영향이 없습니다.</p></div>';
 }
}
load();
})();