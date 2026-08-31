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
