/* CarRanking review form cleanup v1 */
(()=>{
'use strict';
function cleanup(){
  document.getElementById('reviewTitle')?.remove();
  document.getElementById('crEvidence')?.closest('label')?.remove();
}
function boot(){
  cleanup();
  [200,600,1200,2500].forEach(ms=>setTimeout(cleanup,ms));
}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',boot,{once:true});else boot();
})();
