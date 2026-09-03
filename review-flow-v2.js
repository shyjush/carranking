/* CarRanking owner review flow v4
   - submits with member token when logged in
   - explicit success/failure confirmation
   - refreshes public owner ranking/review feed immediately after save
   - lists member's own reviews in MY */
(()=>{
'use strict';
const C=window.CARRANKING_CONFIG||{};
const BASE=String(C.supabaseUrl||'').replace(/\/+$/,'');
const KEY=C.supabasePublishableKey||'';
const TOKEN='carranking_access_token';
const CRITERIA=['ride_comfort','quietness','performance','fuel_efficiency','maintenance_cost','reliability','design','convenience','resale_value','repurchase_intent'];
const $=s=>document.querySelector(s);
const esc=s=>String(s??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));
function visitorId(){let v=localStorage.getItem('carranking_visitor');if(!v){v=(crypto.randomUUID?crypto.randomUUID():`${Date.now()}-${Math.random().toString(36).slice(2)}`);localStorage.setItem('carranking_visitor',v)}return v}
function apiHeaders(){const token=localStorage.getItem(TOKEN);return {apikey:KEY,Authorization:`Bearer ${token||KEY}`,'Content-Type':'application/json'}}
function publicHeaders(){return {apikey:KEY,Authorization:`Bearer ${KEY}`}}
function message(text,ok=false){const box=$('#reviewMessage');if(!box)return;box.innerHTML=`<div style="margin-top:12px;padding:14px 16px;border-radius:14px;font-weight:800;line-height:1.45;background:${ok?'#edf9f2':'#fff4f2'};border:1px solid ${ok?'#bfe6ce':'#f0c7c0'}">${text}</div>`;box.scrollIntoView({behavior:'smooth',block:'nearest'})}
async function rpc(name,payload){const r=await fetch(`${BASE}/rest/v1/rpc/${name}`,{method:'POST',headers:apiHeaders(),body:JSON.stringify(payload)});const t=await r.text();let d=null;try{d=t?JSON.parse(t):null}catch(_){}if(!r.ok){const raw=d?.message||d?.hint||t||`HTTP ${r.status}`;throw new Error(raw)}return d}
async function getView(view,query='select=*'){const r=await fetch(`${BASE}/rest/v1/${view}?${query}`,{headers:publicHeaders(),cache:'no-store'});if(!r.ok)throw new Error(`${view} HTTP ${r.status}`);return r.json()}
function payloadFromForm(form){const sel=$('#reviewVehicle');const p={p_generation_id:sel?.value||'',p_visitor_id:visitorId(),p_title:$('#reviewTitle')?.value||'',p_body:$('#reviewBody')?.value||''};for(const k of CRITERIA)p['p_'+k]=Number(form.querySelector(`[name="${k}"]`)?.value||0);return p}
function renderPublicOwnerUI(ratings,reviews,ranking){
 const summary=$('#reviewSummary'),feed=$('#reviewFeed'),rankBox=$('#ownerRankingList');
 const count=(ratings||[]).reduce((s,r)=>s+Number(r.rating_count||0),0);
 if(summary)summary.innerHTML=`<strong>누적 실제 오너평가 ${count.toLocaleString()}건</strong><span>실제 등록 평점만 오너랭킹에 반영됩니다.</span>`;
 if(feed){
   const owners=(reviews||[]).filter(r=>!r.is_reference);
   feed.innerHTML=owners.length?owners.slice(0,20).map(r=>`<article class="review-card"><div><strong>${esc([r.brand,r.model,r.generation_code||r.generation].filter(Boolean).join(' '))}</strong><span>${esc(r.display_name||'익명 오너')} · ${new Date(r.created_at).toLocaleDateString('ko-KR')}</span></div>${r.title?`<h4>${esc(r.title)}</h4>`:''}<p>${esc(r.body)}</p></article>`).join(''):'<div class="empty"><strong>첫 오너 리뷰를 남겨주세요.</strong><p>아직 공개된 리뷰가 없습니다.</p></div>';
 }
 if(rankBox){
   const rows=[...(ranking||[])].sort((a,b)=>Number(b.overall_score)-Number(a.overall_score)||Number(b.rating_count)-Number(a.rating_count)).slice(0,12);
   rankBox.innerHTML=rows.length?rows.map((r,i)=>`<article class="owner-rank-card" data-gid="${esc(r.generation_id)}"><b>#${i+1}</b><div><strong>${esc(r.brand)} ${esc(r.model)}</strong><span>${esc(r.generation_code||r.generation||'')} · ${Number(r.rating_count||0)}명 실제 평가</span></div><em>${Number(r.overall_score||0).toFixed(1)}</em></article>`).join(''):'<div class="empty"><strong>아직 실제 오너랭킹 데이터가 없습니다.</strong><p>첫 오너평가가 등록되면 자동으로 순위가 생성됩니다.</p></div>';
 }
}
async function refreshPublicOwnerUI(){
 try{
   const [ratings,reviews,ranking]=await Promise.all([
     getView('web_rating_summary','select=*'),
     getView('web_review_feed','select=*&order=is_reference.desc,created_at.desc&limit=40'),
     getView('web_owner_ranking','select=*')
   ]);
   renderPublicOwnerUI(ratings,reviews,ranking);
   return true;
 }catch(e){console.warn('Owner UI refresh failed',e);return false}
}
async function submitReview(e){
 const form=e.target;if(form?.id!=='reviewForm')return;
 e.preventDefault();e.stopImmediatePropagation();
 const b=$('#reviewSubmit');
 const p=payloadFromForm(form);
 if(!p.p_generation_id)return message('⚠️ 차량/세대를 선택해 주세요.');
 if(CRITERIA.some(k=>!p['p_'+k]))return message('⚠️ 10개 평가항목의 점수를 모두 선택해 주세요.');
 if(String(p.p_body).trim().length<10)return message('⚠️ 실제 이용 경험을 10자 이상 입력해 주세요.');
 if(!$('#reviewConfirm')?.checked)return message('⚠️ 공개 게시 동의에 체크해 주세요.');
 b.disabled=true;b.textContent='저장 중…';message('⏳ 평가와 리뷰를 저장하고 있습니다.');
 try{
   const d=await rpc('submit_owner_review',p);
   if(!d?.ok)throw new Error('저장 확인값을 받지 못했습니다.');
   const refreshed=await refreshPublicOwnerUI();
   message(`✅ 저장 완료! 평가·리뷰가 DB에 정상 등록되었습니다.${refreshed?' 오너평점·리뷰 화면에도 즉시 반영했습니다.':' 화면 갱신은 새로고침 후 확인됩니다.'}${d.member?' MY 메뉴에서도 확인할 수 있습니다.':''}`,true);
   try{sessionStorage.setItem('cr_last_review_saved',JSON.stringify({id:d.review_id,ts:Date.now()}))}catch(_){}
   form.reset();
   setTimeout(()=>{window.dispatchEvent(new CustomEvent('cr-review-saved',{detail:d}))},50);
 }catch(err){
   const m=/already reviewed/i.test(err.message)?'이미 이 차량에 등록한 평가가 있습니다.':'저장되지 않았습니다. '+err.message;
   message('⚠️ '+m);
 }finally{b.disabled=false;b.textContent='평가·리뷰 등록'}
}
async function loadMyReviews(){
 const panel=$('#crMyPanel');if(!panel)return;
 let box=$('#crMyReviews');
 if(!box){box=document.createElement('section');box.id='crMyReviews';box.style.cssText='margin-top:22px;padding-top:18px;border-top:1px solid #e5e9ef';const logout=$('#crLogout');(logout?.parentElement||panel).appendChild(box)}
 const token=localStorage.getItem(TOKEN);
 if(!token){box.innerHTML='';return}
 box.innerHTML='<h3 style="margin:0 0 12px">내 오너리뷰</h3><p>불러오는 중…</p>';
 try{
   const rows=await rpc('get_my_owner_reviews',{});
   box.innerHTML='<h3 style="margin:0 0 12px">내 오너리뷰</h3>'+(Array.isArray(rows)&&rows.length?rows.map(r=>`<article style="padding:13px 0;border-top:1px solid #edf0f4"><strong>${esc([r.brand,r.model,r.generation_code||r.generation].filter(Boolean).join(' '))}</strong><div style="margin:5px 0;color:#6b7280;font-size:13px">${new Date(r.created_at).toLocaleDateString('ko-KR')} · ${esc(r.status==='published'?'공개':'상태 '+r.status)}</div>${r.title?`<b>${esc(r.title)}</b>`:''}<p style="margin:6px 0;white-space:pre-wrap">${esc(r.body)}</p></article>`).join(''):'<p style="padding:12px 0;color:#6b7280">아직 등록한 오너리뷰가 없습니다.</p>');
 }catch(err){box.innerHTML='<h3 style="margin:0 0 12px">내 오너리뷰</h3><p style="color:#8b5b55">내 리뷰를 불러오지 못했습니다.</p>'}
}
function install(){
 document.addEventListener('submit',submitReview,true);
 const btn=$('#reviewSubmit');if(btn&&!btn.dataset.crDirect){btn.dataset.crDirect='1';btn.addEventListener('click',e=>{const form=$('#reviewForm');if(form&&form.checkValidity())submitReview({target:form,preventDefault(){e.preventDefault()},stopImmediatePropagation(){e.stopImmediatePropagation()}})},true)}
 document.addEventListener('click',e=>{if(e.target?.closest?.('#crAccountBtn')&&e.target.closest('#crAccountBtn').dataset.mode==='my')setTimeout(loadMyReviews,120)},true);
 window.addEventListener('cr-review-saved',()=>setTimeout(loadMyReviews,150));
}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',install,{once:true});else install();
})();
