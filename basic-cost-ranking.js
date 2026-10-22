'use strict';
const $=id=>document.getElementById(id);
const prices={gas:1700,diesel:1550,lpg:1000,ev:300};
let officialPriceDate=null;
let listed=[];
let registered=[];
function parseRated(s){
 const text=String(s||'');
 if(/최대\s*복합|최소\s*복합/i.test(text))return null;
 const hits=[...text.matchAll(/(\d+(?:\.\d+)?)\s*(km\s*\/\s*(?:kWh|L))/gi)];
 if(hits.length!==1)return null;
 const eff=Number(hits[0][1]);if(!Number.isFinite(eff)||eff<=0||eff>100)return null;
 return {eff,unit:/kwh/i.test(hits[0][2])?'ev':'liquid'};
}
function classified(value){
 const s=String(value||'').toLowerCase();
 if(/전기|electric|\bev\b/.test(s))return 'ev';
 if(/lpg|액화석유/.test(s))return 'lpg';
 if(/디젤|경유|diesel/.test(s))return 'diesel';
 if(/가솔린|휘발유|gasoline|하이브리드|hybrid/.test(s))return 'gas';
 return null;
}
const won=n=>Math.round(n).toLocaleString('ko-KR')+'원';
function buildRow(spec,power,label){
 const rated=parseRated(spec.combined_efficiency),fuel=classified(power.fuel_type);
 if(!rated||!fuel||(rated.unit==='ev')!==(fuel==='ev'))return null;
 if(!/^https:\/\//.test(spec.source_url||'')||!label)return null;
 const cc=Number(power.displacement_cc);
 if(fuel!=='ev'&&(!Number.isInteger(cc)||cc<=0||cc>10000))return null;
 const annualFuel=15000/rated.eff*prices[fuel];
 const base=fuel==='ev'?100000:cc*(cc<=1000?80:cc<=1600?140:200);
 const annualTax=base*1.3;
 return {generation_id:String(spec.generation_id),name:label+' · '+power.name,raw:String(spec.combined_efficiency),fuel,cc: fuel==='ev'?null:cc,eff:rated.eff,source:spec.source_url,fuelCost:annualFuel,taxCost:annualTax,total:annualFuel+annualTax};
}
function render(){
 const query=$('search').value.trim().toLowerCase(),filter=$('fuelFilter').value;
 const items=listed.filter(x=>(!query||x.name.toLowerCase().includes(query))&&(filter==='all'||(filter==='ev'?x.fuel==='ev':x.fuel!=='ev')));
 $('status').textContent='공식 연비·배기량 조건을 충족하는 차량 '+listed.length+'건 · 검색 결과 '+items.length+'건 · '+(officialPriceDate?'오피넷 공식 유가 '+officialPriceDate+' 기준 (전기요금은 예시)':'예시 단가 기준');
 const container=$('cards');container.replaceChildren();
 const missing=$('unranked');missing.replaceChildren();
 if(query){
  const candidates=registered.filter(x=>x.name.toLowerCase().includes(query)&&!listed.some(y=>y.generation_id===x.generation_id)&&(filter==='all'||x.fuels.includes(filter==='ev'?'ev':'liquid')));
  if(filter==='all'||filter==='liquid'||filter==='ev'){
   for(const car of candidates.slice(0,20)){
    const card=document.createElement('article');card.className='vehicle unranked-car';
    const title=document.createElement('h3');title.textContent=car.name;
    const flag=document.createElement('span');flag.className='data-status';flag.textContent='연간 비용 순위 산정 대기';
    const note=document.createElement('p');note.textContent='등록된 차량입니다. 현재 공식 복합연비와 사양별 근거가 확인되지 않아 비용 순위에 표시하지 않습니다.';
    card.append(title,flag,note);missing.append(card);
   }
  }
 }

 if(!items.length){const p=document.createElement('p');p.textContent=missing.children.length?'연간 비용을 계산할 수 있는 차량은 없습니다. 아래에서 등록 차량의 자료 확보 상태를 확인하세요.':'검색 조건에 맞는 차량이 없습니다. 다른 검색어나 연료 종류를 선택해 주세요.';container.append(p);return;}
 items.forEach((item,i)=>{
  const card=document.createElement('article');card.className='vehicle '+(i===0?'rank-first':i===1?'rank-second':i===2?'rank-third':'rank-other');
  const head=document.createElement('h3');
  const num=document.createElement('span');num.className='rank-number';num.textContent=(i+1)+'위';
  head.append(num,document.createTextNode(item.name));card.append(head);
  const amount=document.createElement('div');amount.className='cost';amount.textContent=won(item.total)+' / 년';card.append(amount);
  const d=document.createElement('div');d.className='details';
  for(const [title,price] of [['연료·전력비',item.fuelCost],['자동차세·교육세',item.taxCost]]){
   const cell=document.createElement('div');const b=document.createElement('b');b.textContent=typeof price==='number'?won(price):price;cell.append(document.createTextNode(title),b);d.append(cell);
  }card.append(d);
  const btn=document.createElement('button');btn.type='button';btn.textContent='산출 근거 확인';btn.setAttribute('aria-expanded','false');
  const detail=document.createElement('div');detail.className='detail';detail.hidden=true;
  const text=document.createElement('p');text.textContent='공식자료 표기 연비: '+item.raw+' / '+(item.cc?('DB 배기량: '+item.cc+'cc'):'전기차 정액 자동차세')+' / 연간 15,000km · '+(officialPriceDate&&item.fuel!=='ev'?'오피넷 유가('+officialPriceDate+') ':'예시 단가 ')+prices[item.fuel].toLocaleString('ko-KR')+(item.fuel==='ev'?'원/kWh':'원/L');
  const source=document.createElement('a');source.href=item.source;source.target='_blank';source.rel='noopener noreferrer';source.textContent='연비 원자료 열기 ↗';
  const note=document.createElement('p');note.textContent='표시된 특정 제원·연비 조건에 따른 기본 운영비 추정치입니다.';
  detail.append(text,source,note);btn.addEventListener('click',()=>{detail.hidden=!detail.hidden;btn.setAttribute('aria-expanded',String(!detail.hidden));});
  card.append(btn,detail);container.append(card);
 });
}
$('search').addEventListener('input',render);$('fuelFilter').addEventListener('change',render);
(async()=>{
 try{
  const c=window.CARRANKING_CONFIG;
  if(!c?.useSupabase||!c.supabaseUrl||!c.supabasePublishableKey)throw Error('DB 설정을 사용할 수 없습니다.');
  const h={apikey:c.supabasePublishableKey,Authorization:'Bearer '+c.supabasePublishableKey};
  async function get(path){const r=await fetch(c.supabaseUrl+'/rest/v1/'+path,{headers:h});if(!r.ok)throw Error('자료 조회 HTTP '+r.status);return r.json();}
  try {
   const latest=await get('official_fuel_prices?select=fuel_type,price_krw,price_date&limit=4');
   const byType=new Map(latest.map(x=>[x.fuel_type,x]));
   const dated=latest.filter(x=>['gas','diesel','lpg'].includes(x.fuel_type));
   const valid=dated.length===3&&new Set(dated.map(x=>x.fuel_type)).size===3&&dated.every(x=>x.price_date===dated[0].price_date&&Number(x.price_krw)>=200&&Number(x.price_krw)<=5000);
   if(valid){
    for(const kind of ['gas','diesel','lpg'])prices[kind]=Number(byType.get(kind).price_krw);
    officialPriceDate=dated[0].price_date;
   }
  }catch(e){console.warn('Official fuel prices unavailable: example prices retained',e)}
  const [specs,powers,details]=await Promise.all([
   get('vehicle_specs?select=generation_id,powertrain_id,combined_efficiency,source_url&limit=1000'),
   get('powertrains?select=id,generation_id,name,fuel_type,displacement_cc&limit=1000'),
   get('web_vehicle_detail?select=generation_id,brand,model,generation_code&limit=1000')
  ]);
  const labels=new Map(details.map(v=>[String(v.generation_id),[v.brand,v.model,v.generation_code].filter(Boolean).join(' ')]));
  registered=[...labels].map(([generation_id,name])=>({generation_id,name,fuels:powers.filter(p=>String(p.generation_id)===generation_id).map(p=>classified(p.fuel_type)==='ev'?'ev':classified(p.fuel_type)?'liquid':null).filter(Boolean)}));
  const ids=new Map(powers.map(p=>[String(p.id),p]));
  listed=specs.map(s=>{const p=ids.get(String(s.powertrain_id));return p&&String(p.generation_id)===String(s.generation_id)?buildRow(s,p,labels.get(String(s.generation_id))):null;}).filter(Boolean).sort((a,b)=>a.total-b.total||a.name.localeCompare(b.name,'ko'));
  render();
 }catch(e){$('status').textContent='현재 자료를 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';console.warn('CarRanking basic ranking unavailable',e);}
})();