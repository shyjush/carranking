/* CarRanking admin session bridge v1 */
(()=>{
'use strict';
const C=window.CARRANKING_CONFIG||{};
if(!C.supabaseUrl||!C.supabasePublishableKey)return;
const BASE=String(C.supabaseUrl).replace(/\/+$/,''),KEY=C.supabasePublishableKey;
const ACCESS='carranking_access_token',REFRESH='carranking_refresh_token';
const ONCE='carranking_admin_session_refresh_once';
const get=(k)=>localStorage.getItem(k)||sessionStorage.getItem(k)||'';
const save=(k,v)=>{ if(v) localStorage.setItem(k,v); };
async function refresh(){
  const rt=get(REFRESH); if(!rt)return false;
  const r=await fetch(BASE+'/auth/v1/token?grant_type=refresh_token',{
    method:'POST',
    headers:{apikey:KEY,'Content-Type':'application/json'},
    body:JSON.stringify({refresh_token:rt})
  });
  const t=await r.text(); let d={}; try{d=t?JSON.parse(t):{}}catch(_){}
  if(!r.ok||!d.access_token)return false;
  save(ACCESS,d.access_token); save(REFRESH,d.refresh_token||rt);
  return true;
}
async function ensure(){
  const dashboard=document.getElementById('dashboard');
  if(dashboard && !dashboard.hidden){ sessionStorage.removeItem(ONCE); return; }
  // Admin page legacy code only reads localStorage. Bridge an existing same-tab session first.
  const sessionAccess=sessionStorage.getItem(ACCESS);
  if(!localStorage.getItem(ACCESS)&&sessionAccess){
    localStorage.setItem(ACCESS,sessionAccess);
    if(!sessionStorage.getItem(ONCE)){sessionStorage.setItem(ONCE,'1');location.reload();}
    return;
  }
  if(sessionStorage.getItem(ONCE))return;
  if(await refresh()){
    sessionStorage.setItem(ONCE,'1');
    location.reload();
  }
}
setTimeout(ensure,250);
})();
