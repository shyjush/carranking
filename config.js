// CarRanking runtime configuration
// Publishable key is intentionally safe for browser use; RLS protects exposed data.
window.CARRANKING_CONFIG = {
  supabaseUrl: "https://ikhyadzboorscjwcrhcz.supabase.co",
  supabasePublishableKey: "sb_publishable_1A7C4NeKlg9-mC_9mUjmKg_-wKK_Btw",
  useSupabase: true
};

// The public account UI can keep its session in sessionStorage, while the legacy
// admin page reads localStorage. On /admin, synchronously bridge the active session
// before the admin script runs, and load a robust recovery layer.
const isAdminPage=/^\/admin(?:\/|$)/.test(location.pathname);
if(isAdminPage){
  const ACCESS='carranking_access_token', REFRESH='carranking_refresh_token';
  const sessionAccess=sessionStorage.getItem(ACCESS);
  const sessionRefresh=sessionStorage.getItem(REFRESH);
  if(sessionAccess)localStorage.setItem(ACCESS,sessionAccess);
  if(sessionRefresh)localStorage.setItem(REFRESH,sessionRefresh);
  const adminRecovery=document.createElement('script');
  adminRecovery.src='../admin-login-fix-v3.js?v=3';
  adminRecovery.defer=true;
  document.head.appendChild(adminRecovery);
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

  const simpleSignupScript=document.createElement('script');
  simpleSignupScript.src='simple-signup-v1.js?v=1';
  simpleSignupScript.defer=true;
  document.body.appendChild(simpleSignupScript);

  const rankingBrandExpansion=document.createElement('script');
  rankingBrandExpansion.src='ranking-brand-expansion.js?v=1';
  rankingBrandExpansion.defer=true;
  document.body.appendChild(rankingBrandExpansion);

  const liveRankingSync=document.createElement('script');
  liveRankingSync.src='live-ranking-sync.js?v=1';
  liveRankingSync.defer=true;
  document.body.appendChild(liveRankingSync);

  const myReviewsScript=document.createElement('script');
  myReviewsScript.src='my-reviews-v1.js?v=1';
  myReviewsScript.defer=true;
  document.body.appendChild(myReviewsScript);
}
