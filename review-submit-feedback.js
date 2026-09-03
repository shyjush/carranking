/* CarRanking review submit feedback v1 */
(()=>{
'use strict';
let timer=null;
function ensureStyle(){
 if(document.getElementById('crReviewFeedbackStyle'))return;
 const s=document.createElement('style');s.id='crReviewFeedbackStyle';s.textContent=`
 .cr-save-toast{position:fixed;left:50%;bottom:28px;transform:translateX(-50%);z-index:100000;width:min(560px,calc(100% - 32px));padding:16px 18px;border-radius:16px;background:#10213a;color:#fff;box-shadow:0 16px 44px rgba(0,0,0,.25);font-weight:800;line-height:1.45;text-align:center}.cr-save-toast.ok{background:#146c43}.cr-save-toast.err{background:#a12b2b}.cr-save-toast.wait{background:#204f9c}
 `;document.head.appendChild(s);
}
function toast(text,type='wait',ms=3500){
 ensureStyle();document.getElementById('crSaveToast')?.remove();
 const d=document.createElement('div');d.id='crSaveToast';d.className=`cr-save-toast ${type}`;d.textContent=text;document.body.appendChild(d);
 if(ms>0)setTimeout(()=>d.remove(),ms);
}
function observeMessage(){
 const m=document.getElementById('reviewMessage');if(!m||m.dataset.crSaveWatch)return;
 m.dataset.crSaveWatch='1';
 const read=()=>{
   const t=(m.textContent||'').trim();if(!t)return;
   if(/등록되었습니다|저장되었습니다|반영됩니다|등록 완료|성공/.test(t)){
     clearTimeout(timer);toast('✅ 평가·리뷰가 정상 저장되었습니다. 오너평점과 리뷰에 반영됩니다.','ok',5000);
     setTimeout(()=>document.getElementById('reviewSummary')?.scrollIntoView({behavior:'smooth',block:'center'}),400);
   }else if(/실패|오류|에러|error|HTTP|다시 시도|로그인/.test(t)){
     clearTimeout(timer);toast(`⚠️ 저장되지 않았습니다. ${t}`,'err',6500);
   }
 };
 new MutationObserver(read).observe(m,{childList:true,subtree:true,characterData:true});read();
}
function bind(){
 const form=document.getElementById('reviewForm');if(!form||form.dataset.crSaveFeedback)return;
 form.dataset.crSaveFeedback='1';observeMessage();
 form.addEventListener('submit',()=>{
   clearTimeout(timer);toast('평가·리뷰를 저장하고 있습니다…','wait',0);
   timer=setTimeout(()=>{
     const t=(document.getElementById('reviewMessage')?.textContent||'').trim();
     if(!/등록되었습니다|저장되었습니다|반영됩니다|등록 완료|성공/.test(t))toast('⚠️ 저장 완료 응답을 확인하지 못했습니다. 내용이 저장되지 않았을 수 있으니 다시 확인해 주세요.','err',7000);
   },6500);
 },true);
}
function boot(){bind();[600,1500,3000].forEach(ms=>setTimeout(()=>{bind();observeMessage()},ms))}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',boot,{once:true});else boot();
})();
