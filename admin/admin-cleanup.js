/* CarRanking admin cleanup: remove ownership verification UI */
(()=>{
'use strict';
function hideColumnByHeader(table, labels){
  if(!table) return;
  const headers=[...table.querySelectorAll('thead th')];
  const idx=headers.map((th,i)=>labels.includes((th.textContent||'').trim())?i:-1).filter(i=>i>=0).sort((a,b)=>b-a);
  idx.forEach(i=>{
    table.querySelectorAll('tr').forEach(tr=>tr.children[i]?.remove());
  });
}
function clean(){
  const subtitle=document.querySelector('.top .muted');
  if(subtitle) subtitle.textContent='회원 · 오너리뷰 관리';

  const pending=document.getElementById('pendingCount');
  if(pending) pending.closest('.stat')?.remove();

  const verificationTab=document.querySelector('.tab[data-view="verifications"]');
  if(verificationTab){
    const wasActive=verificationTab.classList.contains('active');
    verificationTab.remove();
    if(wasActive) document.querySelector('.tab[data-view="reviews"]')?.click();
  }

  const auth=document.getElementById('auth');
  if(auth && /실소유 인증/.test(auth.textContent||'')){
    auth.querySelectorAll('p').forEach(p=>{if(/실소유 인증/.test(p.textContent||''))p.textContent='회원·리뷰 데이터를 관리할 수 있습니다.'});
  }

  const table=document.querySelector('#content table');
  if(table){
    hideColumnByHeader(table,['인증','인증리뷰']);
  }
}
function boot(){
  clean();
  const content=document.getElementById('content');
  if(content) new MutationObserver(clean).observe(content,{childList:true,subtree:true});
  document.addEventListener('click',()=>setTimeout(clean,0),true);
  [200,700,1500,3000].forEach(ms=>setTimeout(clean,ms));
}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',boot,{once:true});else boot();
})();
