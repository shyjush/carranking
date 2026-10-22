'use strict';
const assert=require('node:assert/strict'),path=require('node:path');
const {chromium}=require(path.join(process.env.RUNNER_TEMP||'/tmp','carranking-playwright','node_modules','playwright-core'));
(async()=>{
 const browser=await chromium.launch({executablePath:process.env.CHROME_BIN,headless:true,args:['--no-sandbox']});
 try{
  for(const [kind,width] of [['desktop',1280],['mobile',390]]){
   const page=await browser.newPage({viewport:{width,height:844}});
   const r=await page.goto('https://carranking.kr/community.html',{waitUntil:'domcontentloaded',timeout:45000});
   assert(r&&r.ok(),'Community page unavailable');
   await page.waitForFunction(()=>document.querySelectorAll('.community-post .member-discussion-toggle').length>0,{timeout:20000});
   const folded=await page.locator('.community-post .member-discussion-content').first().isVisible();
   assert(!folded,'Comment list must be folded initially');
   await page.locator('.community-post .member-discussion-toggle').first().click();
   assert(await page.locator('.community-post .member-discussion-content').first().isVisible(),'Comment list did not expand');
   await page.waitForFunction(()=>{const t=document.querySelector('.community-post .member-comment-info')?.textContent||'';return t.includes('댓글')||t.includes('못했습니다')},{timeout:12000});
   const info=await page.locator('.community-post .member-comment-info').first().innerText();
   assert(!info.includes('못했습니다'),'Cannot read comment list: '+info);
   await page.locator('.community-post .member-discussion-toggle').first().click();
   assert(!(await page.locator('.community-post .member-discussion-content').first().isVisible()),'Comments did not collapse');
   const review=await browser.newPage({viewport:{width,height:844}});
   await review.goto('https://carranking.kr/',{waitUntil:'domcontentloaded',timeout:45000});
   assert(await review.evaluate(()=>typeof window.CARRANKING_MEMBER_DISCUSSIONS?.makeCommentPanel==='function'),'Owner review comment widget not loaded');
   const layout=await page.evaluate(()=>({screen:innerWidth,document:document.documentElement.scrollWidth}));
   assert(layout.document<=layout.screen+12,'Community horizontal overflow');
   console.log(JSON.stringify({viewport:kind,communityCommentToggle:'pass',read:'pass',ownerCommentModule:'pass'}));
   await review.close();await page.close();
  }
 }finally{await browser.close()}
})().catch(e=>{console.error(e);process.exit(1)});
