'use strict';
const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path');
const {chromium}=require(path.join(process.env.RUNNER_TEMP||'/tmp','carranking-playwright','node_modules','playwright-core'));
(async()=>{
 const browser=await chromium.launch({executablePath:process.env.CHROME_BIN,headless:true,args:['--no-sandbox']});
 const results=[];
 try{
 for(const [name,width] of [['desktop',1280],['mobile',390]]){
 const page=await browser.newPage({viewport:{width,height:844}});
 const resp=await page.goto('https://carranking.kr/economy.html',{waitUntil:'domcontentloaded',timeout:45000});
 assert(resp.ok(),'economy page HTTP '+resp.status());
 await page.fill('#distance','15000');
 await page.fill('#effA','10');await page.fill('#effB','15');
 await page.fill('#priceA','1700');await page.fill('#priceB','1700');
 await page.click('#calculate');
 let output=await page.locator('#results').innerText();
 assert(output.includes('2,550,000원')&&output.includes('1,700,000원')&&output.includes('850,000원'),'Fuel cost wrong: '+output);
 await page.selectOption('#fuelB','ev');await page.fill('#effB','5');await page.fill('#priceB','300');await page.click('#calculate');
 output=await page.locator('#results').innerText();
 assert(output.includes('900,000원')&&output.includes('kWh'),'EV unit/cost wrong: '+output);
 await page.fill('#effA','0');await page.click('#calculate');
 assert((await page.locator('#results').innerText()).includes('유효한 양수'),'Invalid data incorrectly accepted');
 const hidden=await page.locator('#pickWrapA').isVisible();
 assert(!hidden,'Source selector should be hidden in manual mode');
 const parsed=await page.evaluate(()=>[parseEfficiency('복합 9.0 km/L (2WD 18인치 기준)'),parseEfficiency('5.1 km/kWh (19-inch)'),parseEfficiency('미확인')]);
 assert(parsed[0]?.eff===9&&parsed[0]?.unit==='gas'&&parsed[1]?.eff===5.1&&parsed[1]?.unit==='ev'&&parsed[2]===null,'Efficiency parsing incorrect '+JSON.stringify(parsed));
 await page.waitForFunction(()=>document.querySelector('#pickA').options.length>0,{timeout:15000});
 const options=await page.locator('#pickA option').allTextContents();
 assert(options.some(x=>x.includes('K5')&&x.includes('2.0 가솔린')),'K5 powertrain-specific efficiency not selectable');
 assert(options.some(x=>x.includes('아이오닉 5')&&x.includes('Long Range')),'Ioniq 5 powertrain-specific efficiency not selectable');
 assert(options.some(x=>x.includes('G80')&&x.includes('가솔린 2.5 터보 2WD')&&x.includes('10.6 km/L')),'New officially sourced Genesis G80 2WD 10.6 km/L missing from live selector');
 await page.selectOption('#modeA','db');
 assert(await page.locator('#pickWrapA').isVisible(),'DB selector failed to show');
 const k5index=options.findIndex(x=>x.includes('K5')&&x.includes('2.0 가솔린'));
 await page.selectOption('#pickA',String(k5index));
 const linked=await page.evaluate(()=>({eff:Number(document.querySelector('#effA').value),fuel:document.querySelector('#fuelA').value,source:document.querySelector('#sourceA').innerText}));
 assert(linked.eff===12.6&&linked.fuel==='gas'&&linked.source.includes('kia.com'),'Exact K5 economy source did not match: '+JSON.stringify(linked));
 const taxLinked=await page.evaluate(()=>({cc:document.querySelector('#ccA').value,type:document.querySelector('#taxTypeA').value,source:document.querySelector('#taxSourceA').innerText}));
 assert(taxLinked.cc==='1999'&&taxLinked.type==='engine'&&taxLinked.source.includes('K5'),'K5 tax engine linkage incorrect: '+JSON.stringify(taxLinked));
 const evIndex=options.findIndex(x=>x.includes('아이오닉 5')&&x.includes('Long Range'));
 await page.selectOption('#pickA',String(evIndex));
 const taxEv=await page.evaluate(()=>({type:document.querySelector('#taxTypeA').value,source:document.querySelector('#taxSourceA').innerText}));
 assert(taxEv.type==='zero'&&taxEv.source.includes('전기차'),'EV tax type linkage incorrect: '+JSON.stringify(taxEv));
 await page.selectOption('#pickA',String(k5index));

 await page.selectOption('#modeA','manual');
 await page.click('#calculateTax');
 let taxes=await page.locator('#taxResults').innerText();
 assert(taxes.includes('519,740원')&&taxes.includes('290,836원'),'2026 1999cc and 1598cc passenger tax mismatch: '+taxes);
 await page.selectOption('#taxTypeA','zero');
 await page.click('#calculateTax');
 taxes=await page.locator('#taxResults').innerText();
 assert(taxes.includes('130,000원'),'2026 electric passenger tax mismatch: '+taxes);
 await page.selectOption('#taxTypeA','engine');
 await page.fill('#age1A','12');await page.fill('#age2A','12');
 await page.click('#calculateTax');
 taxes=await page.locator('#taxResults').innerText();
 assert(taxes.includes('259,870원'),'12-year automobile reduction incorrect: '+taxes);

 await page.fill('#distance','15000');
 for(const k of ['A','B']){
  await page.fill('#maint-'+k+'-oil-cost',k==='A'?'120000':'90000');
  await page.fill('#maint-'+k+'-oil-cycle','10000');
  await page.fill('#maint-'+k+'-tires-cost',k==='A'?'800000':'600000');
  await page.fill('#maint-'+k+'-tires-cycle','40000');
 }
 await page.click('#maintCalculate');
 let maint=await page.locator('#maintResults').innerText();
 assert(maint.includes('480,000원')&&maint.includes('360,000원')&&maint.includes('120,000원'),'Maintenance annualization incorrect: '+maint);
 await page.fill('#maint-A-oil-cycle','0');
 await page.click('#maintCalculate');
 maint=await page.locator('#maintResults').innerText();
 assert(maint.includes('확인해 주세요'),'Invalid consumable replacement interval was accepted: '+maint);

 await page.fill('#maint-A-oil-cycle','10000');
 await page.fill('#effA','10');await page.fill('#effB','15');
 await page.fill('#priceA','1700');await page.fill('#priceB','1700');
 await page.selectOption('#taxTypeA','engine');
 await page.fill('#age1A','2');await page.fill('#age2A','2');
 await page.click('#summaryCalculate');
 let summary=await page.locator('#summaryResults').innerText();
 assert(summary.includes('3,549,740원')&&summary.includes('2,350,836원'),'Annual partial cost wrong: '+summary);
 assert(summary.includes('10,649,220원')&&summary.includes('7,052,508원'),'3-year scenario wrong: '+summary);
 assert(summary.includes('17,748,700원')&&summary.includes('11,754,180원'),'5-year scenario wrong: '+summary);
 assert(summary.includes('총보유비용(TCO)이 아닙니다'),'Missing non-TCO warning');
 await page.fill('#maint-A-oil-cycle','');
 await page.click('#summaryCalculate');
 summary=await page.locator('#summaryResults').innerText();
 assert(summary.includes('미입력 소모품')&&summary.includes('부분합계'),'Missing component warning absent: '+summary);
 const viewport=await page.evaluate(()=>({width:document.documentElement.scrollWidth,inner:innerWidth}));
 assert(viewport.width<=viewport.inner+24,'Horizontal mobile overflow');
 results.push({name,status:'pass',sourceSelectorHidden:hidden,costValidated:true,evValidated:true,parsingValidated:true});
 await page.close();
 }
 console.log(JSON.stringify({status:'pass',results}));
 }finally{await browser.close()}
})().catch(e=>{console.error(e);process.exit(1)});
