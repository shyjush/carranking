'use strict';
const $=id=>document.getElementById(id);
const rows=[];
function parseEfficiency(value){
 const s=String(value||'');
 const matches=[...s.matchAll(/(\d+(?:\.\d+)?)\s*(km\s*\/\s*kWh|km\s*\/\s*L)/gi)];
 if(matches.length!==1||/최대\s*복합|최소\s*복합/i.test(s))return null;
 const m=matches[0],n=Number(m[1]);
 if(!Number.isFinite(n)||n<=0)return null;
 return {eff:n,unit:/kwh/i.test(m[2])?'ev':'gas',raw:s};
}
const money=n=>Math.round(n).toLocaleString('ko-KR')+'원';
const fuelPrices={gas:1700,diesel:1550,lpg:1000,ev:300};
function suggestUnitPrice(k){
 const kind=$('fuel'+k).value;
 $('price'+k).value=fuelPrices[kind]||1700;
}
function assign(k){const r=rows[Number($('pick'+k).value)];if(!r)return;
 $('eff'+k).value=r.eff;
 $('fuel'+k).value=r.fuel;
 suggestUnitPrice(k);
 if(typeof window.CARRANKING_SYNC_TAX==='function')window.CARRANKING_SYNC_TAX(k,{fuel:r.fuel,cc:r.displacement_cc,label:r.label});
 $('source'+k).textContent=r.label+' · '+r.raw+' · '+r.url+' (구동·휠 사양 확인 필요)';
}
function mode(k){const active=$('mode'+k).value==='db';$('pickWrap'+k).hidden=!active;$('eff'+k).readOnly=active;$('fuel'+k).disabled=active;
 if(active){assign(k);}else{$('source'+k).textContent='사용자 직접 입력값 (공식 검증 연비 아님)';}}
for(const k of ['A','B']){$('fuel'+k).addEventListener('change',()=>suggestUnitPrice(k));$('mode'+k).addEventListener('change',()=>mode(k));$('pick'+k).addEventListener('change',()=>assign(k));$('eff'+k).addEventListener('input',()=>{if($('mode'+k).value==='manual')$('source'+k).textContent='사용자 직접 입력값 (공식 검증 연비 아님)';});}
$('unitPrice').addEventListener('change',()=>{for(const k of ['A','B'])$('price'+k).value=$('unitPrice').value;});
$('calculate').addEventListener('click',()=>{
 const km=Number($('distance').value),values=[];
 for(const k of ['A','B']){
  const eff=Number($('eff'+k).value),price=Number($('price'+k).value);
  if(!(km>0&&km<=100000&&eff>0&&eff<=100&&price>0&&price<=10000)){
   $('results').textContent='주행거리·연비·연료 단가를 유효한 양수로 입력해 주세요.';return;
  }
  values.push({k,total:km/eff*price,quantity:km/eff,unit:$('fuel'+k).value==='ev'?'kWh':'L'});
 }
 const d=Math.abs(values[0].total-values[1].total);
 $('results').innerHTML=values.map(x=>'<div class="econ-result">차량 '+x.k+' 예상 연간 연료·전력 사용량 '+x.quantity.toFixed(1)+x.unit+'<strong>'+money(x.total)+'</strong></div>').join('')+'<div class="econ-warning">예상 연간 차이: <strong>'+money(d)+'</strong> · '+(values[0].total===values[1].total?'두 차량 동일':values[0].total<values[1].total?'차량 A 연료비가 낮음':'차량 B 연료비가 낮음')+'<br>실제 비용·종합 유지비 순위가 아니라 입력 조건에 따른 단순 연료비 비교입니다.</div>';
});
(async()=>{
 try{
  const c=window.CARRANKING_CONFIG;
  if(!c?.useSupabase||!c.supabaseUrl||!c.supabasePublishableKey)throw Error('DB configuration unavailable');
  const headers={apikey:c.supabasePublishableKey,Authorization:'Bearer '+c.supabasePublishableKey};
  const base=c.supabaseUrl+'/rest/v1/';
  const get=async path=>{const r=await fetch(base+path,{headers});if(!r.ok)throw Error('DB HTTP '+r.status);return r.json();};
  const [specs,vehicles,powertrains]=await Promise.all([get('vehicle_specs?select=generation_id,powertrain_id,combined_efficiency,source_url&limit=1000'),get('web_vehicle_detail?select=generation_id,brand,model,generation_code&limit=1000'),get('powertrains?select=id,generation_id,name,fuel_type,displacement_cc&limit=1000')]);
  const labels=new Map(vehicles.map(v=>[String(v.generation_id),[v.brand,v.model,v.generation_code].filter(Boolean).join(' ')]));
  const powers=new Map(powertrains.map(p=>[String(p.id),p]));
  for(const spec of specs){
   const e=parseEfficiency(spec.combined_efficiency);
   const power=powers.get(String(spec.powertrain_id));
   if(!e||!power||String(power.generation_id)!==String(spec.generation_id)||!/^https:\/\//.test(spec.source_url||'')||!labels.has(String(spec.generation_id)))continue;
   const kind=String(power.fuel_type||'').toLowerCase();
   const declared=/전기|electric|\bev\b/.test(kind)?'ev':/lpg|액화석유/.test(kind)?'lpg':/diesel|디젤|경유/.test(kind)?'diesel':/gasoline|가솔린|휘발유|하이브리드|hybrid/.test(kind)?'gas':null;
   if(!declared||(declared==='ev')!==(e.unit==='ev'))continue;
   const fuel=declared;
   rows.push({...e,fuel,displacement_cc:power.displacement_cc,url:spec.source_url,label:labels.get(String(spec.generation_id))+' · '+power.name});
  }
  rows.sort((a,b)=>a.label.localeCompare(b.label,'ko'));
  for(const k of ['A','B']){$('pick'+k).innerHTML=rows.map((r,i)=>'<option value="'+i+'">'+r.label+' · '+r.raw+'</option>').join('');if(rows.length===0)$('mode'+k).querySelector('[value="db"]').disabled=true;}
 }catch(e){for(const k of ['A','B'])$('mode'+k).querySelector('[value="db"]').disabled=true;console.warn('Official efficiency selector unavailable',e);}
})();// No data write; calculation only.
