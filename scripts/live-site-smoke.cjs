'use strict';
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const {chromium}=require(process.env.PLAYWRIGHT_CORE_PATH ||
 path.join(process.env.RUNNER_TEMP||'/tmp','carranking-playwright','node_modules','playwright-core'));

const URL=process.env.CARRANKING_LIVE_URL||'https://carranking.kr/';
const expectedAppVersion=fs.readFileSync('index.html','utf8').match(/app\.js\?v=\d+/)?.[0];
assert(expectedAppVersion,'Repo index.html does not declare a versioned app.js');
const CHROME=process.env.CHROME_BIN||'/usr/bin/google-chrome';
const outDir=path.join(process.cwd(),'site-smoke-artifacts');
fs.mkdirSync(outDir,{recursive:true});
const report={url:URL,at:new Date().toISOString(),results:[],status:'failed'};
const wait=ms=>new Promise(r=>setTimeout(r,ms));
let browser;

async function testViewport(name,width,height){
 const page=await browser.newPage({viewport:{width,height},deviceScaleFactor:1});
 const result={name,viewport:{width,height},url:URL,status:'failed'};
 report.results.push(result);
 try{
  let response;
  for(let attempt=1;attempt<=3;attempt++){
   try{
    response=await page.goto(URL,{waitUntil:'domcontentloaded',timeout:40000});
    if(response && response.ok())break;
    throw new Error('HTTP '+(response?.status()??'no response'));
   }catch(e){
    if(attempt===3)throw e;
    await wait(6000);
   }
  }
  assert(response && response.ok(),'Real website HTTP failure');
  await page.waitForFunction(()=>Boolean(window.CARRANKING_VERIFIED_READY&&window.CARRANKING_OPEN_DETAIL),{timeout:20000});
  await page.evaluate(async()=>{await window.CARRANKING_VERIFIED_READY});
  await page.waitForTimeout(5000); // Also let home-fixes.js perform its delayed annual ranking overrides.
  const dom=await page.evaluate(()=>{
   const q=s=>document.querySelector(s);
   const verified=window.CARRANKING_VERIFIED_RANKING||[];
   return {
    title:document.title,
    hero:q('#economyHeroCard')?.innerText||'',
    legacyHidden:['historicalRanking','ranking','heroCard'].every(id=>{const el=document.getElementById(id);return !!el&&getComputedStyle(el).display==='none'}),
    economyPrimary:!!document.querySelector('.hero .actions a.btn.primary[href="/basic-cost-ranking.html"]'),
    ranking:q('#rankingBody')?.innerText||'',
    visibleRows:document.querySelectorAll('#rankingBody tr.clickable-row').length,
    verifiedCount:verified.length,
    bestWorstCards:document.querySelectorAll('#editorialPreview .live-value-card').length,
    compareOptions:q('#compare1')?.options.length||0,
    reviewOptions:q('#reviewVehicle')?.options.length||0,
    menuLinks:document.querySelectorAll('header a').length,
    pageWidth:document.documentElement.scrollWidth,
    viewportWidth:window.innerWidth,
    jsVersion:[...document.scripts].map(e=>e.src).filter(s=>s.includes('/app.js?')).join(','),
   };
  });
  result.dom=dom;
  assert(dom.title.includes('CarRanking'),'Wrong website or missing page title');
  assert(dom.legacyHidden&&dom.economyPrimary&&dom.hero.includes('기본 유지비'),'Old ranking visible or new economy hero missing');
  assert(dom.jsVersion.includes(expectedAppVersion),'Stale CarRanking app script on live site: expected '+expectedAppVersion);
  assert(dom.menuLinks>0,'Site navigation not rendered');
  assert(dom.compareOptions>1&&dom.reviewOptions>1,'Car model selectors not populated from own DB');
  assert.equal(dom.visibleRows,dom.verifiedCount,'Public ranking differs from verified DB rows');
  if(dom.verifiedCount===0){
    assert(dom.ranking.includes('검증'),'Zero-evidence state not disclosed in ranking table');
    assert(dom.hero.includes('예시 연료 단가'),'Economy homepage missing partial-cost disclaimer');
    assert.equal(dom.bestWorstCards,0,'Unverified BEST/WORST content leaked into public site');
  }
  await page.screenshot({path:path.join(outDir,name+'-ranking.png'),fullPage:true});
  const detail=await page.evaluate(()=>{
    const opener=window.CARRANKING_OPEN_DETAIL;
    if(typeof opener!=='function')return{error:'Missing detail opener'};
    opener('제네시스','G80','DH');
    return {visible:!document.querySelector('#vehicleDetail')?.classList.contains('hidden'),
      text:document.querySelector('#detailContent')?.innerText||'',
      title:document.querySelector('#detailTitle')?.innerText||''};
  });
  result.detail={visible:detail.visible,title:detail.title,hasReferenceDate:/공통정보 기준일\s+\d{4}-\d{2}-\d{2}\s*검증/.test(detail.text),
    hasDimension:detail.text.includes('4,990')||detail.text.includes('4990')};
  assert(detail.visible,'G80 DH detail panel not visible');
  assert(detail.title.includes('G80'),'Wrong G80 DH details');
  assert(result.detail.hasDimension,'New verified G80 DH specifications missing from actual detail screen');
  assert(result.detail.hasReferenceDate,'G80 DH common information verification date missing');
  await page.screenshot({path:path.join(outDir,name+'-G80-DH-detail.png'),fullPage:true});
  const newSpecModels=[
    ['현대','캐스퍼','AX1','3,595'],['현대','스타리아','US4','5,255'],
    ['현대','아이오닉 6','CE','4,855'],['제네시스','G90','RS4','5,275'],
    ['BMW','X3','G45','4,755'],['렉서스','NX','AZ20','4,660'],
    ['현대','투싼','TL','4,480'],['현대','팰리세이드','LX2','4,980'],
    ['현대','싼타페','TM','4,770'],['현대','베뉴','QX','4,040'],
    ['현대','넥쏘','FE','4,670']
  ];
  const verifiedSpecs=await page.evaluate((expectations)=>{
    const result=[];
    for(const [brand,model,generation,dimension] of expectations){
      window.CARRANKING_OPEN_DETAIL(brand,model,generation);
      const title=document.querySelector('#detailTitle')?.innerText||'';
      const body=document.querySelector('#detailContent')?.innerText||'';
      result.push({brand,model,generation,dimension,visible:title.includes(model)&&title.includes(generation),
        dimensionMatched:body.includes(dimension),basisPresent:/공통정보 기준일\s+\d{4}-\d{2}-\d{2}\s*검증/.test(body)});
    }
    return result;
  },newSpecModels);
  result.bulkSpecs={checked:verifiedSpecs.length,passed:verifiedSpecs.filter(x=>x.visible&&x.dimensionMatched&&x.basisPresent).length,
    failed:verifiedSpecs.filter(x=>!(x.visible&&x.dimensionMatched&&x.basisPresent))};
  assert.equal(result.bulkSpecs.passed,newSpecModels.length,
    'Not every new official-source specification is visible on the real website: '+JSON.stringify(result.bulkSpecs.failed));

  if(width<600)assert(dom.pageWidth<=dom.viewportWidth+24,'Mobile page overflows horizontal viewport');
  result.status='pass';
 }catch(e){
  result.error=String(e.stack||e);
  try{await page.screenshot({path:path.join(outDir,name+'-failure.png'),fullPage:true})}catch(_){}
 }finally{await page.close()}
 return result;
}
(async()=>{
 try{
  assert(fs.existsSync(CHROME),'Chrome executable not present: '+CHROME);
  browser=await chromium.launch({executablePath:CHROME,headless:true,args:['--no-sandbox','--disable-dev-shm-usage']});
  for(const [name,w,h] of [['desktop',1440,900],['mobile',390,844]]){
   await testViewport(name,w,h);
  }
  report.status=report.results.every(x=>x.status==='pass')?'pass':'failed';
 }catch(e){report.error=String(e.stack||e)}
 finally{
  if(browser)await browser.close();
  fs.writeFileSync(path.join(outDir,'result.json'),JSON.stringify(report,null,2)+'\n');
  console.log(JSON.stringify(report,null,2));
  if(report.status!=='pass')process.exitCode=1;
 }
})();
