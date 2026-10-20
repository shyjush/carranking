'use strict';
// 2026 Korea Local Tax Act art.127: standard noncommercial passenger automobile tax only.
// Two statutory tax periods may have different vehicle age. Never infer legal vehicle age from model year.
function computeAnnualTax(type,cc,age1,age2){
 if(!Number.isInteger(age1)||!Number.isInteger(age2)||age1<1||age2<1||age1>99||age2>99)throw Error('차령을 정확히 입력해 주세요.');
 if(type!=='engine'&&type!=='zero')throw Error('지원하지 않는 과세 유형입니다.');
 if(type==='engine'&&(!Number.isInteger(cc)||cc<1||cc>10000))throw Error('배기량을 확인해 주세요.');
 const annualBase=type==='zero'?100000:cc*(cc<=1000?80:cc<=1600?140:200);
 const halfTax=age=>annualBase/2*(type==='zero'?1:1-Math.min(Math.max(age-2,0),10)*0.05);
 const carTax=halfTax(age1)+halfTax(age2);
 return {carTax,educationTax:carTax*.3,total:carTax*1.3};
}
function updateTaxType(k){
 const zero=document.getElementById('taxType'+k).value==='zero';
 const inp=document.getElementById('cc'+k);
 inp.disabled=zero;
 inp.closest('label').style.opacity=zero?'.5':'1';
 for(const p of ['age1','age2'])document.getElementById(p+k).disabled=zero;
}
for(const k of ['A','B']){
 document.getElementById('taxType'+k).addEventListener('change',()=>updateTaxType(k));
 updateTaxType(k);
}
document.getElementById('calculateTax').addEventListener('click',()=>{
 const fmt=n=>Math.round(n).toLocaleString('ko-KR')+'원';
 try{
  const result={};
  for(const k of ['A','B']){
   const type=document.getElementById('taxType'+k).value;
   result[k]=computeAnnualTax(type,Number(document.getElementById('cc'+k).value),
    type==='zero'?1:Number(document.getElementById('age1'+k).value),
    type==='zero'?1:Number(document.getElementById('age2'+k).value));
  }
  document.getElementById('taxResults').textContent='';
  for(const k of ['A','B']){
   const c=document.createElement('div');c.className='econ-result';
   c.textContent='차량 '+k+' · 예상 자동차세 '+fmt(result[k].carTax)+' + 지방교육세 '+fmt(result[k].educationTax);
   const b=document.createElement('strong');b.textContent=fmt(result[k].total);c.appendChild(b);
   document.getElementById('taxResults').appendChild(c);
  }
  const note=document.createElement('div');note.className='econ-warning';
  note.textContent='두 차량 예상 자동차세 차이: '+fmt(Math.abs(result.A.total-result.B.total))+' · 연료비와 별개 계산입니다.';
  document.getElementById('taxResults').appendChild(note);
 }catch(e){document.getElementById('taxResults').textContent=String(e.message);}
});
