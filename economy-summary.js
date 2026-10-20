'use strict';
// This is an illustrative sum of named cost components, not full vehicle TCO.
// Tax is held at current entered half-year ages for 3/5y illustrations; future age reduction is NOT projected.
const $cost=id=>document.getElementById(id);
const costMoney=n=>Math.round(n).toLocaleString('ko-KR')+'원';
function summaryFor(k,km){
 const efficiency=Number($cost('eff'+k).value),unitCost=Number($cost('price'+k).value);
 if(!Number.isFinite(km)||km<=0||km>100000||!Number.isFinite(efficiency)||efficiency<=0||efficiency>100||!Number.isFinite(unitCost)||unitCost<=0||unitCost>10000)throw Error('차량 '+k+'의 주행거리·연비·연료단가를 확인해 주세요.');
 const fuel=km/efficiency*unitCost;
 const taxType=$cost('taxType'+k).value;
 const tax=computeAnnualTax(taxType,Number($cost('cc'+k).value),taxType==='zero'?1:Number($cost('age1'+k).value),taxType==='zero'?1:Number($cost('age2'+k).value)).total;
 const consumables=annualConsumable(k,km);
 return {fuel,tax,consumables:consumables.total,rows:consumables.rows,subtotal:fuel+tax+consumables.total};
}
$cost('summaryCalculate').addEventListener('click',()=>{
 const root=$cost('summaryResults');
 root.textContent='';
 try{
  const km=Number($cost('distance').value);
  const results={A:summaryFor('A',km),B:summaryFor('B',km)};
  const shared=results.A.rows.map(x=>x.title).filter(name=>results.B.rows.some(y=>y.title===name));
  const complete=shared.length===4&&results.A.rows.length===4&&results.B.rows.length===4;
  const selectedCount=results.A.rows.length+results.B.rows.length;
  const table=document.createElement('table');
  table.style.width='100%';table.style.borderCollapse='collapse';table.style.marginTop='14px';
  const head=document.createElement('tr');
  for(const t of ['비용 구분','차량 A','차량 B']){const th=document.createElement('th');th.textContent=t;th.style.textAlign='left';th.style.padding='12px 6px';head.appendChild(th);}
  table.appendChild(head);
  for(const [title,fn] of [['연료·전력 비용',x=>x.fuel],['자동차세 + 지방교육세',x=>x.tax],['입력한 소모품만',x=>x.consumables],['연간 부분합계',x=>x.subtotal]]){
   const tr=document.createElement('tr');for(const t of [title,costMoney(fn(results.A)),costMoney(fn(results.B))]){
    const td=document.createElement('td');td.textContent=t;td.style.padding='11px 6px';td.style.borderTop='1px solid #dce2ea';tr.appendChild(td);
   }table.appendChild(tr);
  }
  root.appendChild(table);
  const note=document.createElement('div');note.className='econ-warning';note.style.marginTop='12px';
  note.textContent=selectedCount===0?'소모품은 양쪽 모두 미입력으로, 합계에서 제외됐습니다.':complete?'입력된 네 가지 소모품을 모두 반영한 부분합계입니다.':'주의: 미입력 소모품이 있으며 양쪽 입력 항목이 다를 수 있습니다. 비교 대상 소모품을 동일하게 입력해 주세요.';
  root.appendChild(note);
  for(const years of [1,3,5]){
   const box=document.createElement('div');box.className='econ-result';
   const a=results.A.subtotal*years,b=results.B.subtotal*years;
   box.textContent=years+'년 단순 누적 부분합계 · A '+costMoney(a)+' / B '+costMoney(b)+' / 차이 '+costMoney(Math.abs(a-b));
   root.appendChild(box);
  }
  const caveat=document.createElement('p');caveat.className='econ-note';
  caveat.textContent='3·5년 금액은 연간 입력값을 그대로 곱한 단순 시나리오입니다. 미래 유가·주행거리·세율·차령 경감 변동은 반영하지 않습니다. 보험료·차량구입비·감가상각비·고장 수리·기타 미입력 소모품은 포함하지 않아 총보유비용(TCO)이 아닙니다.';
  root.appendChild(caveat);
 }catch(e){root.textContent=String(e.message);}
});
