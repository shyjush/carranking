// CarRanking runtime configuration
// Publishable key is intentionally safe for browser use; RLS protects exposed data.
window.CARRANKING_CONFIG = {
  supabaseUrl: "https://ikhyadzboorscjwcrhcz.supabase.co",
  supabasePublishableKey: "sb_publishable_1A7C4NeKlg9-mC_9mUjmKg_-wKK_Btw",
  useSupabase: true
};

// The public account UI can keep its session in sessionStorage, while the legacy
// admin page reads localStorage. On /admin, bridge both stores and transparently
// refresh/substitute the latest bearer token before the legacy admin code runs.
const isAdminPage=/^\/admin(?:\/|$)/.test(location.pathname);
if(isAdminPage){
  const ACCESS='carranking_access_token', REFRESH='carranking_refresh_token';
  const sessionAccess=sessionStorage.getItem(ACCESS);
  const sessionRefresh=sessionStorage.getItem(REFRESH);
  if(sessionAccess)localStorage.setItem(ACCESS,sessionAccess);
  if(sessionRefresh)localStorage.setItem(REFRESH,sessionRefresh);

  const nativeFetch=window.fetch.bind(window);
  const supabaseOrigin=new URL(window.CARRANKING_CONFIG.supabaseUrl).origin;
  const latestAccess=()=>localStorage.getItem(ACCESS)||sessionStorage.getItem(ACCESS)||'';
  const latestRefresh=()=>localStorage.getItem(REFRESH)||sessionStorage.getItem(REFRESH)||'';
  let refreshPromise=null;

  async function refreshAdminSession(){
    if(refreshPromise)return refreshPromise;
    const rt=latestRefresh();
    if(!rt)return null;
    refreshPromise=(async()=>{
      try{
        const r=await nativeFetch(supabaseOrigin+'/auth/v1/token?grant_type=refresh_token',{
          method:'POST',
          headers:{apikey:window.CARRANKING_CONFIG.supabasePublishableKey,'Content-Type':'application/json'},
          body:JSON.stringify({refresh_token:rt})
        });
        if(!r.ok)return null;
        const d=await r.json();
        if(!d?.access_token)return null;
        localStorage.setItem(ACCESS,d.access_token);
        if(d.refresh_token)localStorage.setItem(REFRESH,d.refresh_token);
        return d.access_token;
      }catch(_){return null}
      finally{refreshPromise=null}
    })();
    return refreshPromise;
  }

  window.fetch=async function(input,init={}){
    const url=typeof input==='string'?input:input?.url||'';
    if(!url.startsWith(supabaseOrigin))return nativeFetch(input,init);
    const headers=new Headers(init.headers||(typeof input!=='string'?input.headers:undefined)||{});
    const current=latestAccess();
    if(current && headers.has('Authorization'))headers.set('Authorization','Bearer '+current);
    let response=await nativeFetch(input,{...init,headers});
    if((response.status===401||response.status===403) && headers.has('Authorization')){
      const refreshed=await refreshAdminSession();
      if(refreshed){
        headers.set('Authorization','Bearer '+refreshed);
        response=await nativeFetch(input,{...init,headers});
      }
    }
    return response;
  };
}else{
  const homeFixesScript=document.createElement('script');
  homeFixesScript.src='home-fixes.js';
  homeFixesScript.defer=true;
  document.body.appendChild(homeFixesScript);

  const reputationScript=document.createElement('script');
  reputationScript.src='car-reputation.js?v=1.2';
  reputationScript.defer=true;
  document.body.appendChild(reputationScript);

  const engagementScript=document.createElement('script');
  engagementScript.src='car-engagement-v120.js?v=1.20';
  engagementScript.defer=true;
  document.body.appendChild(engagementScript);

  const reviewFeedbackScript=document.createElement('script');
  reviewFeedbackScript.src='review-submit-feedback.js?v=1';
  reviewFeedbackScript.defer=true;
  document.body.appendChild(reviewFeedbackScript);

  const ownerDisplayHotfix=document.createElement('script');
  ownerDisplayHotfix.src='owner-display-hotfix.js?v=7';
  ownerDisplayHotfix.defer=true;
  document.body.appendChild(ownerDisplayHotfix);

  const reviewFormCleanup=document.createElement('script');
  reviewFormCleanup.src='review-form-cleanup-v1.js?v=1';
  reviewFormCleanup.defer=true;
  document.body.appendChild(reviewFormCleanup);

  const linkAuditScript=document.createElement('script');
  linkAuditScript.src='link-audit.js?v=1';
  linkAuditScript.defer=true;
  document.body.appendChild(linkAuditScript);

  const runtimeQaScript=document.createElement('script');
  runtimeQaScript.src='runtime-qa.js?v=1';
  runtimeQaScript.defer=true;
  document.body.appendChild(runtimeQaScript);

  // Instant signup: existing email logs in; new email is created without confirmation mail, then logged in.
  const simpleSignupScript=document.createElement('script');
  simpleSignupScript.src='simple-signup-v1.js?v=1';
  simpleSignupScript.defer=true;
  document.body.appendChild(simpleSignupScript);

  // Ranking filter uses the full domestic/import vehicle catalog while value-ranking rows remain verified-only.
  const rankingBrandExpansion=document.createElement('script');
  rankingBrandExpansion.src='ranking-brand-expansion.js?v=1';
  rankingBrandExpansion.defer=true;
  document.body.appendChild(rankingBrandExpansion);

  // Keep the homepage ranking and hero card synced directly to the live Supabase ranking view.
  const liveRankingSync=document.createElement('script');
  liveRankingSync.src='live-ranking-sync.js?v=1';
  liveRankingSync.defer=true;
  document.body.appendChild(liveRankingSync);

  // MY screen: show reviews written by the currently authenticated member.
  const myReviewsScript=document.createElement('script');
  myReviewsScript.src='my-reviews-v1.js?v=1';
  myReviewsScript.defer=true;
  document.body.appendChild(myReviewsScript);
}
