// CarRanking runtime configuration
// Publishable key is intentionally safe for browser use; RLS protects exposed data.
window.CARRANKING_CONFIG = {
  supabaseUrl: "https://ikhyadzboorscjwcrhcz.supabase.co",
  supabasePublishableKey: "sb_publishable_1A7C4NeKlg9-mC_9mUjmKg_-wKK_Btw",
  useSupabase: true
};

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

// Stable public owner dashboard: no MutationObserver loop, no repaint interval.
const ownerDisplayHotfix=document.createElement('script');
ownerDisplayHotfix.src='owner-display-hotfix.js?v=7';
ownerDisplayHotfix.defer=true;
document.body.appendChild(ownerDisplayHotfix);

// Simplify review form: remove optional one-line title and proof-link field.
const reviewFormCleanup=document.createElement('script');
reviewFormCleanup.src='review-form-cleanup-v1.js?v=1';
reviewFormCleanup.defer=true;
document.body.appendChild(reviewFormCleanup);

// Navigation audit: keep every public hash link tied to the intended section.
const linkAuditScript=document.createElement('script');
linkAuditScript.src='link-audit.js?v=1';
linkAuditScript.defer=true;
document.body.appendChild(linkAuditScript);
