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
 await page.selectOption('#modeA','db');
 assert(await page.locator('#pickWrapA').isVisible(),'DB selector failed to show');
 const k5index=options.findIndex(x=>x.includes('K5')&&x.includes('2.0 가솔린'));
 await page.selectOption('#pickA',String(k5index));
 const linked=await page.evaluate(()=>({eff:Number(document.querySelector('#effA').value),fuel:document.querySelector('#fuelA').value,source:document.querySelector('#sourceA').innerText}));
 assert(linked.eff===12.6&&linked.fuel==='gas'&&linked.source.includes('kia.com'),'Exact K5 economy source did not match: '+JSON.stringify(linked));
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
 const viewport=await page.evaluate(()=>({width:document.documentElement.scrollWidth,inner:innerWidth}));
 assert(viewport.width<=viewport.inner+24,'Horizontal mobile overflow');
 results.push({name,status:'pass',sourceSelectorHidden:hidden,costValidated:true,evValidated:true,parsingValidated:true});
 await page.close();
 }
 console.log(JSON.stringify({status:'pass',results}));
 }finally{await browser.close()}
})().catch(e=>{console.error(e);process.exit(1)});
