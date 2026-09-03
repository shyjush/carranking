/* CarRanking owner review flow v3 */
(()=>{
'use strict';
const C=window.CARRANKING_CONFIG||{};
const BASE=String(C.supabaseUrl||'').replace(/\/+$/,'');
const KEY=C.supabasePublishableKey||'';
const TOKEN='carranking_access_token';
const CRITERIA=['ride_comfort','quietness','performance','fuel_efficiency','maintenance_cost','reliability','design','convenience','resale_value','repurchase_intent'];
const $=s=>document.querySelector(s);
const esc=s=>String(s??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));
let saving=false;
function visitorId(){let v=localStorage.getItem('carranking_visitor');if(!v){v=(crypto.randomUUID?crypto.randomUUID():`${Date.now()}-${Math.random().toString(36).slice(2)}`);localStorage.setItem('carranking_visitor',v)}return v}
function apiHeaders(){const token=localStorage.getItem(TOKEN);return {apikey:KEY,Authorization:`Bearer ${token||KEY}`,'Content-Type':'application/json'}}
function ensureMessageBox(){let box=$('#reviewMessage');if(!box){box=document.createElement('div');box.id='reviewMessage';$('#reviewForm')?.appendChild(box)}return box}
function message(text,ok=false){const box=ensureMessageBox();if(!box)return;box.innerHTML=`<div style="margin-top:14px;padding:15px 16px;border-radius:14px;font-weight:900;line-height:1.5;background:${ok?'#edf9f2':'#fff4f2'};border:2px solid ${ok?'#61b77e':'#e7a49b'};color:#233043">${text}</div>`;box.scrollIntoView({behavior:'smooth',block:'center'})}
async function rpc(name,payload){const r=await fetch(`${BASE}/rest/v1/rpc/${name}`,{method:'POST',headers:apiHeaders(),body:JSON.stringify(payload)});const t=await r.text();let d=null;try{d=t?JSON.parse(t):null}catch(_){}if(!r.ok){throw new Error(d?.message||d?.hint||t||`HTTP ${r.status}`)}return d}
function payloadFromForm(form){const p={p_generation_id:$('#reviewVehicle')?.value||'',p_visitor_id:visitorId(),p_title:$('#reviewTitle')?.value||'',p_body:$('#reviewBody')?.value||''};for(const k of CRITERIA)p['p_'+k]=Number(form.querySelector(`[name="${k}"]`)?.value||0);return p}
async function saveNow(){
 if(saving)return;
 const form=$('#reviewForm'),b=$('#reviewSubmit');if(!form||!b)return;
 const p=payloadFromForm(form);
 if(!p.p_generation_id)return message('⚠️ 차량/세대를 선택해 주세요.');
 const missing=CRITERIA.find(k=>!p['p_'+k]);if(missing)return message('⚠️ 10개 평가항목의 점수를 모두 선택해 주세요.');
 if(String(p.p_body).trim().length<10)return message('⚠️ 실제 이용 경험을 10자 이상 입력해 주세요.');
 if(!$('#reviewConfirm')?.checked)return message('⚠️ 공개 게시 동의에 체크해 주세요.');
 saving=true;b.disabled=true;b.textContent='저장 중…';message('⏳ 저장 요청 중입니다. 잠시만 기다려 주세요.');
 try{
   const d=await rpc('submit_owner_review',p);
   if(!d?.ok)throw new Error('DB 저장 확인값을 받지 못했습니다.');
   message(`✅ 저장 완료! 평가·리뷰가 DB에 정상 등록되었습니다.${d.member?' MY 메뉴에서 확인할 수 있습니다.':''}`,true);
   try{localStorage.setItem('cr_last_review_saved',JSON.stringify({review_id:d.review_id,ts:Date.now()}))}catch(_){}
   window.dispatchEvent(new CustomEvent('cr-review-saved',{detail:d}));
   form.reset();
 }catch(err){
   const m=/already reviewed/i.test(String(err.message))?'이미 이 차량에 등록한 평가가 있습니다.':'DB에 저장되지 않았습니다. '+err.message;
   message('⚠️ '+m,false);
 }finally{saving=false;b.disabled=false;b.textContent='평가·리뷰 등록'}
}
async function loadMyReviews(){
 const panel=$('#crMyPanel');if(!panel)return;
 let box=$('#crMyReviews');if(!box){box=document.createElement('section');box.id='crMyReviews';box.style.cssText='margin-top:22px;padding-top:18px;border-top:1px solid #e5e9ef';panel.appendChild(box)}
 if(!localStorage.getItem(TOKEN)){box.innerHTML='';return}
 box.innerHTML='<h3 style="margin:0 0 12px">내 오너리뷰</h3><p>불러오는 중…</p>';
 try{const rows=await rpc('get_my_owner_reviews',{});box.innerHTML='<h3 style="margin:0 0 12px">내 오너리뷰</h3>'+(Array.isArray(rows)&&rows.length?rows.map(r=>`<article style="padding:13px 0;border-top:1px solid #edf0f4"><strong>${esc([r.brand,r.model,r.generation_code||r.generation].filter(Boolean).join(' '))}</strong><div style="margin:5px 0;color:#6b7280;font-size:13px">${new Date(r.created_at).toLocaleDateString('ko-KR')} · ${esc(r.status==='published'?'공개':'상태 '+r.status)}</div>${r.title?`<b>${esc(r.title)}</b>`:''}<p style="margin:6px 0;white-space:pre-wrap">${esc(r.body)}</p></article>`).join(''):'<p style="padding:12px 0;color:#6b7280">아직 등록한 오너리뷰가 없습니다.</p>')}catch(_){box.innerHTML='<h3>내 오너리뷰</h3><p>내 리뷰를 불러오지 못했습니다.</p>'}
}
function install(){
 const b=$('#reviewSubmit'),form=$('#reviewForm');
 if(b){b.type='button';b.onclick=e=>{e.preventDefault();e.stopPropagation();saveNow()}}
 if(form)form.onsubmit=e=>{e.preventDefault();saveNow();return false};
 document.addEventListener('click',e=>{const a=e.target?.closest?.('#crAccountBtn');if(a&&a.dataset.mode==='my')setTimeout(loadMyReviews,150)},true);
 window.addEventListener('cr-review-saved',()=>setTimeout(loadMyReviews,200));
}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',install,{once:true});else install();
})();
