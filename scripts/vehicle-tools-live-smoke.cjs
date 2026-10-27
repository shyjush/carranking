'use strict';
const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path');
const {chromium}=require(process.env.PLAYWRIGHT_CORE_PATH||'playwright');
const origin=process.env.CARRANKING_LIVE_URL||'https://carranking.kr';
const out=process.env.CARRANKING_QA_DIR||'site-smoke-artifacts';fs.mkdirSync(out,{recursive:true});
(async()=>{
 const browser=await chromium.launch({executablePath:process.env.CHROME_BIN,headless:true,args:['--no-sandbox','--disable-dev-shm-usage']});const report={origin,at:new Date().toISOString(),screens:[]};
 try{for(const [kind,width] of [['desktop',1360],['mobile',390]]){
  const context=await browser.newContext({viewport:{width,height:844},isMobile:kind==='mobile',hasTouch:kind==='mobile'}),page=await context.newPage(),errors=[];
  page.on('pageerror',e=>errors.push(e.message));
  const response=await page.goto(origin+'/vehicle-tools.html',{waitUntil:'domcontentloaded',timeout:45000});assert(response.ok());
  await page.waitForFunction(()=>document.querySelector('#loadStatus').textContent.includes('수신 완료'),{timeout:45000});
  const loaded=await page.locator('#loadStatus').innerText(),counts=loaded.match(/(\d+)개 세대.*?(\d+)건.*수신 완료/);
  assert(counts&&Number(counts[1])>=179&&Number(counts[2])>=411,loaded);
  await page.selectOption('#model0',{label:'기아 K5 DL3'});assert.equal(await page.inputValue('#spec0'),'');
  await page.locator('#calculate').click();assert((await page.locator('#inputError').innerText()).includes('직접 선택'));
  const variants=await page.locator('#spec0 option').evaluateAll(opts=>opts.map(x=>({value:x.value,label:x.textContent})).filter(x=>x.value));assert.equal(variants.length,28);
  await page.selectOption('#spec0',variants[0].value);await page.selectOption('#model1',{label:'기아 K5 DL3'});await page.selectOption('#spec1',variants[1].value);
  assert.equal(await page.locator('.result').count(),2);assert((await page.locator('#results').innerText()).includes('공식 인증자료'));
  const before=Number((await page.locator('.result .amount').first().innerText()).replace(/\D/g,''));await page.fill('#insurance0','800000');
  const after=Number((await page.locator('.result .amount').first().innerText()).replace(/\D/g,''));assert.equal(after-before,800000);
  await page.fill('#km','20000');await page.fill('#gas','1800');await page.locator('#calculate').click();assert.equal(await page.locator('#inputError').innerText(),'');
  assert((await page.locator('#results').innerText()).includes('사용자 입력'));
  const firstText=await page.locator('.result').first().innerText();assert(firstText.includes('미입력·합계 제외')&&firstText.includes('800,000원'));
  await page.selectOption('#model2',{label:'기아 EV3 SV'});const ev=await page.locator('#spec2 option').evaluateAll(opts=>opts.map(x=>x.value).filter(Boolean));assert(ev.length>0);await page.selectOption('#spec2',ev[0]);assert.equal(await page.locator('.result').count(),3);
  const dims=await page.evaluate(()=>({viewport:innerWidth,page:document.documentElement.scrollWidth}));assert(dims.page<=dims.viewport+2,'Unexpected page overflow '+JSON.stringify(dims));
  await page.locator('#results').scrollIntoViewIfNeeded();await page.screenshot({path:path.join(out,kind+'-cost-comparison.png')});
  await page.locator('#reset').click();assert.equal(await page.inputValue('#insurance0'),'');assert.equal(await page.inputValue('#model0'),'');
  assert.equal(errors.length,0,errors.join('\n'));
  report.screens.push({kind,width,status:'passed',loaded,modelVariants:variants.length,threeWayComparison:true,insuranceAdded:800000,overflow:dims,pageErrors:errors});await context.close();
 }
 report.status='passed';fs.writeFileSync(path.join(out,'vehicle-tools-live.json'),JSON.stringify(report,null,2));console.log(JSON.stringify(report));
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
