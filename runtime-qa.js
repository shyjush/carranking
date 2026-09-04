/* CarRanking runtime QA guard */
(()=>{'use strict';
function installStyle(){
 if(document.getElementById('crRuntimeQaStyle'))return;
 const s=document.createElement('style');s.id='crRuntimeQaStyle';s.textContent=`
select,input,textarea,button,a{touch-action:manipulation}
#reviewVehicle,#scoreBrand,#scoreVehicle,#compare1,#compare2,#compare3{pointer-events:auto!important;position:relative;z-index:2}
`;
 document.head.appendChild(s);
}
function ensureControls(){
 ['reviewVehicle','scoreBrand','scoreVehicle','compare1','compare2','compare3'].forEach(id=>{const el=document.getElementById(id);if(el){el.disabled=false;el.style.pointerEvents='auto'}});
}
function reviewMessage(text){const m=document.getElementById('reviewMessage');if(m)m.textContent=text}
function bind(){
 ensureControls();
 document.addEventListener('submit',e=>{
   const f=e.target;if(f?.id!=='reviewForm')return;
   const vehicle=document.getElementById('reviewVehicle');
   if(!vehicle?.value){
     e.preventDefault();e.stopImmediatePropagation();
     reviewMessage('먼저 차량/세대를 선택해 주세요.');
     vehicle?.focus();vehicle?.scrollIntoView({behavior:'smooth',block:'center'});
     return;
   }
   const missing=[...f.querySelectorAll('select[required]')].find(x=>!x.value);
   if(missing){
     e.preventDefault();e.stopImmediatePropagation();
     reviewMessage('평가항목을 모두 선택해 주세요.');
     missing.focus();missing.scrollIntoView({behavior:'smooth',block:'center'});
   }
 },true);
 document.addEventListener('click',e=>{
   const a=e.target.closest?.('a[href^="#"]');if(!a)return;
   const id=(a.getAttribute('href')||'').slice(1);if(!id)return;
   if(document.getElementById(id))return;
   e.preventDefault();
   console.warn('[CarRanking] blocked missing target',id);
   const msg=document.getElementById('reviewMessage');if(msg)msg.textContent='요청한 화면을 찾지 못했습니다. 다시 시도해 주세요.';
 },true);
 const root=document.body;if(root)new MutationObserver(ensureControls).observe(root,{childList:true,subtree:true});
}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',()=>{installStyle();bind()},{once:true});else{installStyle();bind()}
})();