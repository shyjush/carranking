/* CarRanking lightweight participation UX v1.20
   - no broad MutationObserver
   - keeps existing anonymous/member review flows untouched
   - adds homepage participation CTA, first-review prompt, reward copy, post-review comparison
*/
(()=>{
'use strict';
const C=window.CARRANKING_CONFIG||{};
const BASE=String(C.supabaseUrl||'').replace(/\/+$/,'');
const KEY=C.supabasePublishableKey||'';
const TOKEN_KEY='carranking_access_token';
const PENDING_KEY='cr_engagement_pending_review';
const CRITERIA=['ride_comfort','quietness','performance','fuel_efficiency','maintenance_cost','reliability','design','convenience','resale_value','repurchase_intent'];
const esc=s=>String(s??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));
const avg=a=>{const v=a.map(Number).filter(Number.isFinite);return v.length?v.reduce((x,y)=>x+y,0)/v.length:null};
const fmt=n=>Number(n).toFixed(1);
const isMember=()=>Boolean(localStorage.getItem(TOKEN_KEY));

function styles(){
 if(document.getElementById('crEngagementStyle'))return;
 const s=document.createElement('style');s.id='crEngagementStyle';s.textContent=`
 .cr-engage{margin:22px 0;padding:22px 24px;border-radius:24px;background:linear-gradient(135deg,#173f7a 0%,#2465b8 48%,#2aa7a1 100%);color:#fff;box-shadow:0 16px 38px rgba(28,75,126,.18);position:relative;overflow:hidden}.cr-engage:after{content:'🚘';position:absolute;right:24px;top:6px;font-size:78px;opacity:.11}.cr-engage .cr-eyebrow{font-size:11px;font-weight:900;letter-spacing:.12em;opacity:.85}.cr-engage h2{margin:7px 0 7px;font-size:24px;color:#fff}.cr-engage p{margin:0 0 14px;line-height:1.55;opacity:.95}.cr-engage-benefits{display:grid;grid-template-columns:repeat(3,1fr);gap:8px;margin:14px 0}.cr-engage-benefits span{background:rgba(255,255,255,.14);border-radius:12px;padding:10px 8px;text-align:center;font-size:12px}.cr-engage-actions{display:flex;gap:9px;flex-wrap:wrap}.cr-engage-actions button,.cr-engage-actions a{appearance:none;border-radius:999px;padding:11px 16px;font-weight:900;text-decoration:none;cursor:pointer}.cr-engage-primary{border:0;background:#fff;color:#174b85}.cr-engage-secondary{border:1px solid rgba(255,255,255,.42);background:rgba(255,255,255,.11);color:#fff}
 .cr-engage-reward{margin:10px 0 14px;padding:12px 14px;border-radius:14px;background:#eef6ff;border:1px solid #cfe1f5;color:#345879;font-size:13px;line-height:1.5}.cr-engage-reward b{color:#185397}.cr-first-owner{margin:10px 0 14px;padding:12px 14px;border-radius:14px;background:linear-gradient(90deg,#fff5d9,#fff);border:1px solid #ead28c;color:#6a5317;font-size:13px;line-height:1.5;font-weight:800}
 .cr-result-backdrop{position:fixed;inset:0;background:rgba(15,28,45,.52);z-index:99999;display:flex;align-items:center;justify-content:center;padding:18px}.cr-result-card{width:min(520px,100%);background:#fff;border-radius:24px;padding:24px;box-shadow:0 24px 70px rgba(16,34,55,.3);position:relative}.cr-result-card h2{margin:0 0 4px;font-size:22px}.cr-result-car{color:#617184;font-size:13px;margin-bottom:16px}.cr-scoregrid{display:grid;grid-template-columns:1fr 1fr;gap:10px}.cr-scorebox{border-radius:16px;padding:16px;text-align:center;background:#f6f9fd;border:1px solid #dce7f2}.cr-scorebox span{display:block;font-size:12px;color:#68798b}.cr-scorebox strong{display:block;font-size:30px;margin-top:3px;color:#1d619d}.cr-diff{margin:13px 0;padding:12px;border-radius:13px;background:#eef8f7;color:#315e5b;text-align:center;font-weight:800}.cr-result-points{text-align:center;font-size:13px;color:#5e6d7b;margin-bottom:15px}.cr-result-actions{display:flex;gap:8px;justify-content:center;flex-wrap:wrap}.cr-result-actions button{border-radius:999px;padding:10px 15px;font-weight:900;cursor:pointer}.cr-result-main{border:0;background:linear-gradient(90deg,#1c5e9b,#24958f);color:#fff}.cr-result-sub{border:1px solid #c8d7e4;background:#fff;color:#35556f}.cr-result-close{position:absolute;right:14px;top:12px;border:0;background:transparent;font-size:24px;cursor:pointer;color:#71808d}
 @media(max-width:760px){.cr-engage{padding:18px}.cr-engage h2{font-size:20px}.cr-engage-benefits{grid-template-columns:1fr}.cr-scoregrid{grid-template-columns:1fr 1fr}.cr-result-card{padding:20px}}
 `;document.head.appendChild(s);
}

function addHomeCard(){
 const hero=document.querySelector('#top .hero');if(!hero||document.getElementById('crEngageCard'))return;
 const d=document.createElement('section');d.id='crEngageCard';d.className='section cr-engage';
 d.innerHTML=`<div class="cr-eyebrow">MY CAR EXPERIENCE</div><h2>지금 타는 차, 몇 점 주시겠어요?</h2><p>30초 오너평가로 내 자동차 경험을 기록하고, 다른 실제 오너들의 평균과 비교해보세요.</p><div class="cr-engage-benefits"><span>🚗 회원 오너리뷰 +100P</span><span>📊 내 점수 vs 전체 오너 평균</span><span>🏅 실소유·장기보유 배지</span></div><div class="cr-engage-actions"><button type="button" class="cr-engage-primary" id="crEngageStart">30초 오너평가 시작</button><a class="cr-engage-secondary" href="#ownerRanking">오너랭킹 먼저 보기</a></div>`;
 hero.insertAdjacentElement('afterend',d);
 document.getElementById('crEngageStart')?.addEventListener('click',()=>{document.getElementById('reviews')?.scrollIntoView({behavior:'smooth',block:'start'});setTimeout(()=>document.getElementById('reviewVehicle')?.focus(),300)});
}

function enhanceReviewForm(){
 const form=document.getElementById('reviewForm');if(!form)return;
 if(!document.getElementById('crEngageReward')){
   const d=document.createElement('div');d.id='crEngageReward';d.className='cr-engage-reward';d.innerHTML='<b>30초 오너평가</b> · 회원 리뷰는 +100P, 실소유 인증 승인 시 추가 +200P가 반영됩니다. 평점의 높고 낮음은 보상과 무관합니다.';
   form.querySelector('h3')?.insertAdjacentElement('afterend',d);
 }
 if(!document.getElementById('crFirstOwner')){
   const d=document.createElement('div');d.id='crFirstOwner';d.className='cr-first-owner';d.hidden=true;form.querySelector('#reviewVehicle')?.insertAdjacentElement('afterend',d);
 }
 const sel=document.getElementById('reviewVehicle');if(sel&&!sel.dataset.crEngagement){sel.dataset.crEngagement='1';sel.addEventListener('change',updateFirstPrompt);}
}

async function getSummary(gid){
 if(!BASE||!KEY||!gid)return null;
 const r=await fetch(`${BASE}/rest/v1/web_rating_summary?select=generation_id,overall_score,rating_count&generation_id=eq.${encodeURIComponent(gid)}&limit=1`,{headers:{apikey:KEY,Authorization:`Bearer ${KEY}`}});
 if(!r.ok)return null;const rows=await r.json();return rows[0]||null;
}
async function updateFirstPrompt(){
 const sel=document.getElementById('reviewVehicle'),box=document.getElementById('crFirstOwner');if(!sel||!box)return;
 const gid=sel.value;if(!gid){box.hidden=true;return}
 try{const s=await getSummary(gid);if(!s||Number(s.rating_count||0)===0){box.innerHTML=`🏆 <b>${esc(sel.options[sel.selectedIndex]?.text||'이 차량')}</b>의 첫 오너평가자가 되어주세요. 첫 실제 평가가 등록되면 오너랭킹 산정이 시작됩니다.`;box.hidden=false}else box.hidden=true}catch(_){box.hidden=true}
}

function snapshotDraft(){
 const form=document.getElementById('reviewForm'),sel=document.getElementById('reviewVehicle');if(!form||!sel?.value)return null;
 const scores=CRITERIA.map(k=>Number(form.querySelector(`[name="${k}"]`)?.value||0));if(scores.some(v=>!v))return null;
 const draft={gid:sel.value,label:sel.options[sel.selectedIndex]?.text||'차량',score:avg(scores),member:isMember(),ts:Date.now()};
 try{sessionStorage.setItem(PENDING_KEY,JSON.stringify(draft))}catch(_){}
 return draft;
}
function readPending(){try{const d=JSON.parse(sessionStorage.getItem(PENDING_KEY)||'null');if(!d||Date.now()-Number(d.ts||0)>10000)return null;return d}catch(_){return null}}
function clearPending(){try{sessionStorage.removeItem(PENDING_KEY)}catch(_){}}
function closeResult(){document.getElementById('crResultBackdrop')?.remove()}
async function showComparison(draft){
 if(!draft?.gid||draft.score==null)return;
 let s=null;try{s=await getSummary(draft.gid)}catch(_){}
 const community=s&&Number.isFinite(Number(s.overall_score))?Number(s.overall_score):Number(draft.score);
 const count=Number(s?.rating_count||0),diff=Number(draft.score)-community;
 const msg=count<=1?'🎉 이 차량의 첫 실제 오너평가 기록이 되었습니다.':Math.abs(diff)<.05?'📊 전체 오너 평균과 거의 같은 평가입니다.':diff>0?`📈 전체 오너보다 ${fmt(Math.abs(diff))}점 높게 평가했습니다.`:`📉 전체 오너보다 ${fmt(Math.abs(diff))}점 낮게 평가했습니다.`;
 closeResult();
 const d=document.createElement('div');d.id='crResultBackdrop';d.className='cr-result-backdrop';
 d.innerHTML=`<div class="cr-result-card" role="dialog" aria-modal="true"><button class="cr-result-close" aria-label="닫기">×</button><h2>🚗 오너평가가 등록되었습니다!</h2><div class="cr-result-car">${esc(draft.label)}</div><div class="cr-scoregrid"><div class="cr-scorebox"><span>내 종합평점</span><strong>${fmt(draft.score)}</strong></div><div class="cr-scorebox"><span>전체 오너 평균</span><strong>${fmt(community)}</strong></div></div><div class="cr-diff">${msg}</div><div class="cr-result-points">${draft.member?'🎉 회원 리뷰 +100P · 내 CarRank에 기록':'내 자동차 경험이 오너평점 데이터에 반영되었습니다.'}</div><div class="cr-result-actions"><button class="cr-result-main" data-cr-result="again">다른 차 평가</button><button class="cr-result-sub" data-cr-result="rank">오너랭킹 보기</button></div></div>`;
 document.body.appendChild(d);clearPending();
 d.querySelector('.cr-result-close')?.addEventListener('click',closeResult);
 d.addEventListener('click',e=>{if(e.target===d)closeResult();const a=e.target.closest?.('[data-cr-result]');if(!a)return;closeResult();document.getElementById(a.dataset.crResult==='rank'?'ownerRanking':'reviews')?.scrollIntoView({behavior:'smooth',block:'start'})});
}

function watchSubmission(){
 document.addEventListener('click',e=>{if(e.target.closest?.('#reviewSubmit')){const draft=snapshotDraft();if(!draft)return;[350,700,1300,2200].forEach(ms=>setTimeout(()=>{const msg=document.getElementById('reviewMessage')?.textContent||'';if(/등록되었습니다|반영됩니다/.test(msg)){showComparison(draft)}},ms))}},true);
 const form=document.getElementById('reviewForm');if(form&&!form.dataset.crEngageSubmit){form.dataset.crEngageSubmit='1';form.addEventListener('submit',()=>{snapshotDraft()},false)}
}

function resumeAfterMemberReload(){
 const d=readPending();if(!d||!d.member)return;
 setTimeout(async()=>{const fresh=readPending();if(!fresh)return;await showComparison(fresh)},900);
}
function boot(){styles();addHomeCard();enhanceReviewForm();watchSubmission();resumeAfterMemberReload();[500,1200,2200].forEach(ms=>setTimeout(()=>{enhanceReviewForm();updateFirstPrompt()},ms))}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',boot,{once:true});else boot();
})();
