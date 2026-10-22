'use strict';
const assert=require('node:assert/strict'),path=require('node:path');
const {chromium}=require(path.join(process.env.RUNNER_TEMP||'/tmp','carranking-playwright','node_modules','playwright-core'));
(async()=>{
 const browser=await chromium.launch({executablePath:process.env.CHROME_BIN,headless:true,args:['--no-sandbox']});
 try{
  for(const [kind,width] of [['desktop',1280],['mobile',390]]){
   const page=await browser.newPage({viewport:{width,height:844}});
   const response=await page.goto('https://carranking.kr/basic-cost-ranking.html',{waitUntil:'domcontentloaded',timeout:45000});
   assert(response&&response.ok(),'Ranking HTTP unavailable');
   await page.waitForFunction(()=>document.querySelectorAll('#cards .vehicle').length>2,{timeout:20000});
   const cards=await page.locator('#cards .vehicle').count();
   const values=await page.locator('#cards .vehicle .cost').allTextContents();
   const amounts=values.map(s=>Number(s.replace(/[^0-9]/g,'')));
   assert(amounts.every((v,i)=>i===0||v>=amounts[i-1]),'Ranking amounts not sorted');
   const tileCounts=await page.locator('#cards .vehicle .details').evaluateAll(xs=>xs.map(x=>x.children.length));
   assert(tileCounts.every(n=>n===2),'Every card should have exactly two automatic cost tiles');
   const classes=await page.locator('#cards .vehicle').evaluateAll(xs=>xs.slice(0,3).map(x=>x.className));
   assert(classes[0].includes('rank-first')&&classes[1].includes('rank-second')&&classes[2].includes('rank-third'),'Top 3 color classes absent');
   assert.equal(await page.getByText('합산 범위',{exact:true}).count(),0,'Unnecessary scope column remains');
   assert.equal(await page.locator('details summary').count(),0,'Manual advanced input still advertised');
   await page.fill('#search','Gv80');
   const initialGv=await page.locator('#cards').innerText();
   assert(initialGv.includes('GV80'),'GV80 not searchable in verified ranking');
   await page.fill('#search','GV80');
   const gv80Result=await page.locator('#cards').innerText();
   assert(gv80Result.includes('GV80')&&gv80Result.includes('연료·전력비')&&gv80Result.includes('자동차세'),'Official GV80 efficiency is not included in ranking: '+gv80Result);
   for(const model of ['K8','니로','모닝']){
    await page.fill('#search',model);
    const found=await page.locator('#cards').innerText();
    assert(found.includes(model)&&found.includes('연료·전력비')&&found.includes('자동차세'),'New manufacturer-sourced efficiency missing for '+model+': '+found);
   }
   await page.fill('#search','EV3');
   await page.waitForFunction(()=>document.querySelector('#officialCatalog')?.innerText.includes('한국에너지공단 공식 인증자료'),{timeout:20000});
   const officialResults=await page.locator('#officialCatalog').innerText();
   assert(officialResults.includes('EV3')&&officialResults.includes('인증')&&officialResults.includes('연비')||officialResults.includes('전비'),'New KEA vehicle catalog EV3 search missing: '+officialResults);
   await page.fill('#search','G80');
   const results=await page.locator('#cards').innerText();
   assert(results.includes('G80')&&!results.includes('K5'),'Vehicle search incorrect');
   await page.locator('.vehicle button').first().click();
   assert(await page.locator('.vehicle .detail').first().isVisible(),'Evidence toggle broken');
   await page.selectOption('#fuelFilter','ev');
   assert.equal(await page.locator('.vehicle').count(),0,'EV filter ignored');
   const widthInfo=await page.evaluate(()=>[document.documentElement.scrollWidth,innerWidth]);
   assert(widthInfo[0]<=widthInfo[1]+24,'Mobile horizontal overflow');
   await page.goto('https://carranking.kr/economy.html',{waitUntil:'domcontentloaded',timeout:45000});
   await page.waitForURL('**/basic-cost-ranking.html',{timeout:15000});
   assert(page.url().includes('basic-cost-ranking.html'),'Retired calculator did not redirect');
   console.log(JSON.stringify({viewport:kind,status:'pass',cars:cards,automaticCostTiles:2,manualCalculatorRedirect:true}));
   await page.close();
  }
 }finally{await browser.close()}
})().catch(e=>{console.error(e);process.exit(1)});
