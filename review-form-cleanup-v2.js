/* CarRanking review form cleanup v2 */
(()=>{
'use strict';
function clean(){
  document.getElementById('reviewTitle')?.remove();
  const evidence=document.getElementById('crEvidence');
  if(evidence){
    const label=evidence.closest('label');
    if(label) label.remove(); else evidence.remove();
  }
}
function boot(){
  clean();
  [100,300,700,1500,3000].forEach(ms=>setTimeout(clean,ms));
}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',boot,{once:true});else boot();
})();
