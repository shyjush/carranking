/* CarRanking navigation hardening */
(()=>{'use strict';
const valid=['top','ranking','ownerRanking','compare','score','reviews'];
function target(id){return document.getElementById(id)}
function focusFor(id){
  if(id==='reviews')setTimeout(()=>document.getElementById('reviewVehicle')?.focus({preventScroll:true}),180);
  if(id==='score')setTimeout(()=>document.getElementById('scoreBrand')?.focus({preventScroll:true}),180);
  if(id==='compare')setTimeout(()=>document.getElementById('compare1')?.focus({preventScroll:true}),180);
}
function go(id){const el=target(id);if(!el)return false;history.replaceState(null,'','#'+id);el.scrollIntoView({behavior:'smooth',block:'start'});focusFor(id);return true}
function bind(){
 document.addEventListener('click',e=>{
   const a=e.target.closest?.('a[href^="#"]');if(!a)return;
   const id=(a.getAttribute('href')||'').slice(1);if(!id)return;
   if(valid.includes(id)){
     e.preventDefault();
     if(!go(id))console.warn('[CarRanking] missing navigation target:',id);
   }
 },true);
 // Initial-screen owner review CTA always lands on the actual review form.
 document.querySelectorAll('a[href="#reviews"]').forEach(a=>a.title='오너 리뷰 작성 화면으로 이동');
}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',bind,{once:true});else bind();
})();