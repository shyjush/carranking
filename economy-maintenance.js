'use strict';
// User-supplied cost and replacement cycle only; not manufacturer specifications or a price quote.
const groups=[['oil','엔진오일·필터'],['tires','타이어 1세트'],['brakes','브레이크 패드'],['other','기타 소모품']];
function annualConsumable(k,km){
 if(!Number.isFinite(km)||km<=0||km>100000)throw Error('연간 주행거리를 확인해 주세요.');
 const result=[];
 for(const [name,title] of groups){
  const costField=document.getElementById('maint-'+k+'-'+name+'-cost');
  const cycleField=document.getElementById('maint-'+k+'-'+name+'-cycle');
  const cost=Number(costField.value),cycle=Number(cycleField.value);
  if(costField.value.trim()===''||cycleField.value.trim()==='')continue;
  if(!Number.isFinite(cost)||cost<0||cost>100000000||!Number.isFinite(cycle)||cycle<=0||cycle>1000000)throw Error(k+' 차량 '+title+'의 비용·교체주기를 확인해 주세요.');
  result.push({title,cost,cycle,annual:km*cost/cycle});
 }
 return {total:result.reduce((acc,row)=>acc+row.annual,0),rows:result};
}
const fmt=n=>Math.round(n).toLocaleString('ko-KR')+'원';
function buildFields(k){
 const root=document.getElementById('maintFields'+k);
 for(const [name,title] of groups){
  const row=document.createElement('div');row.className='maint-row';
  const titleEl=document.createElement('strong');titleEl.textContent=title;row.appendChild(titleEl);
  for(const [suffix,label] of [['cost','교체 1회 총비용(원)'],['cycle','교체 간격(km)']]){
   const lbl=document.createElement('label');lbl.textContent=label;
   const input=document.createElement('input');input.id='maint-'+k+'-'+name+'-'+suffix;
   input.type='number';input.min=suffix==='cost'?'0':'1';input.step='1';input.placeholder='미입력 시 제외';
   lbl.appendChild(input);row.appendChild(lbl);
  }
  root.appendChild(row);
 }
}
for(const k of ['A','B'])buildFields(k);
document.getElementById('maintCalculate').addEventListener('click',()=>{
 const output=document.getElementById('maintResults');
 output.textContent='';
 try{
  const km=Number(document.getElementById('distance').value);
  const a=annualConsumable('A',km),b=annualConsumable('B',km);
  if(!a.rows.length||!b.rows.length){
   output.textContent='A·B 차량 모두 최소 1종 이상의 비용과 교체주기를 입력해야 비교할 수 있습니다. 미입력 항목은 계산에서 제외됩니다.';
   return;
  }
  for(const [key,data] of [['A',a],['B',b]]){
   const div=document.createElement('div');div.className='econ-result';
   const h=document.createElement('div');h.textContent='차량 '+key+' · 입력한 소모품만 계산';div.appendChild(h);
   const amount=document.createElement('strong');amount.textContent=fmt(data.total);div.appendChild(amount);
   const detail=document.createElement('small');
   detail.textContent=data.rows.map(r=>r.title+' '+fmt(r.annual)+'/년').join(' · ');
   div.appendChild(detail);output.appendChild(div);
  }
  const note=document.createElement('div');note.className='econ-warning';
  note.textContent='두 차량 연간 예상 소모품 비용 차이: '+fmt(Math.abs(a.total-b.total))+' · 실제 정비 견적이 아니며, 미입력 소모품·공임·사용연수 기준 교체 등은 반영되지 않습니다.';
  output.appendChild(note);
 }catch(e){output.textContent=String(e.message);}
});
