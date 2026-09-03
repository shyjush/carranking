// CarRanking runtime configuration
// Publishable key is intentionally safe for browser use; RLS protects exposed data.
window.CARRANKING_CONFIG = {
  supabaseUrl: "https://ikhyadzboorscjwcrhcz.supabase.co",
  supabasePublishableKey: "sb_publishable_1A7C4NeKlg9-mC_9mUjmKg_-wKK_Btw",
  useSupabase: true
};

// Home UX enhancements: robust TOP5 display + clearly labeled editorial reference-review previews.
const homeFixesScript=document.createElement('script');
homeFixesScript.src='home-fixes.js';
homeFixesScript.defer=true;
document.body.appendChild(homeFixesScript);

// Member reputation UX: email login, points/levels/badges, long-term owner fields and helpful votes.
const reputationScript=document.createElement('script');
reputationScript.src='car-reputation.js?v=1.2';
reputationScript.defer=true;
document.body.appendChild(reputationScript);

// Lightweight participation UX: 30-second owner review CTA, first-review prompt, score comparison.
const engagementScript=document.createElement('script');
engagementScript.src='car-engagement-v120.js?v=1.20';
engagementScript.defer=true;
document.body.appendChild(engagementScript);

// Review save feedback: show clear success/failure notification after submission.
const reviewFeedbackScript=document.createElement('script');
reviewFeedbackScript.src='review-submit-feedback.js?v=1';
reviewFeedbackScript.defer=true;
document.body.appendChild(reviewFeedbackScript);

// Force owner ranking/review display to refresh independently from optional homepage APIs.
const ownerDisplayHotfix=document.createElement('script');
ownerDisplayHotfix.src='owner-display-hotfix.js?v=1';
ownerDisplayHotfix.defer=true;
document.body.appendChild(ownerDisplayHotfix);
