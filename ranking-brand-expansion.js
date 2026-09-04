/* CarRanking ranking brand expansion v1 */
(()=>{'use strict';
const C=window.CARRANKING_CONFIG||{},BASE=String(C.supabaseUrl||'').replace(/\/+$/,''),KEY=C.supabasePublishableKey||'';
const esc=s=>String(s??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));
async function get(path){const r=await fetch(BASE+'/rest/v1/'+path,{headers:{apikey:KEY},cache:'no-store'});if(!r.ok)throw new Error('HTTP '+r.status);return r.json()}
function pct(v){return v==null?'정보 없음':(Number(v)*100).toFixed(1)+'%'}
async function boot(){
 const filter=document.getElementById('brandFilter'),cat=document.getElementById('categoryFilter'),body=document.getElementById('rankingBody');
 if(!filter||!body||!BASE||!KEY)return;
 try{
   const [vehicles,ranking]=await Promise.all([
     get('web_vehicle_detail?select=brand,category&order=brand.asc'),
     get('web_value_ranking?select=*&order=retention_rate.desc')
   ]);
   const brands=[...new Set(vehicles.map(x=>x.brand).filter(Boolean))].sort((a,b)=>a.localeCompare(b,'ko'));
   const categories=[...new Set(vehicles.map(x=>x.category).filter(Boolean))].sort((a,b)=>a.localeCompare(b,'ko'));
   const currentBrand=filter.value,currentCat=cat?.value||'';
   filter.innerHTML='<option value="">전체 브랜드</option>'+brands.map(v=>`<option value="${esc(v)}">${esc(v)}</option>`).join('');
   if(currentBrand&&brands.includes(currentBrand))filter.value=currentBrand;
   if(cat){cat.innerHTML='<option value="">전체 차급</option>'+categories.map(v=>`<option value="${esc(v)}">${esc(v)}</option>`).join('');if(currentCat&&categories.includes(currentCat))cat.value=currentCat;}
   function render(){
     const b=filter.value,c=cat?.value||'';
     const rows=ranking.filter(x=>(!b||x.brand===b)&&(!c||x.category===c));
     if(!rows.length){
       const label=b?`${esc(b)}의 가치보존율 랭킹 데이터는 현재 수집·검증 중입니다.`:'선택 조건에 맞는 가치보존율 데이터가 아직 없습니다.';
       body.innerHTML=`<tr><td colspan="6" style="padding:28px;text-align:center"><strong>${label}</strong><br><span style="color:#64748b">차량 검색·비교·오너평가는 이용할 수 있으며, 검증된 중고시세가 확보되는 순서대로 랭킹에 추가됩니다.</span></td></tr>`;
       return;
     }
     body.innerHTML=rows.map((x,i)=>`<tr class="clickable-row" data-brand="${esc(x.brand)}" data-model="${esc(x.model)}" data-generation="${esc(x.generation_code||x.generation||'')}"><td><strong>#${x.rank??i+1}</strong></td><td><strong>${esc(x.brand)} ${esc(x.model)}</strong><span class="muted-dark small">${esc(x.generation_code||x.generation||'')}</span></td><td>${esc(x.model_year??'-')}</td><td><span class="badge">${pct(x.retention_rate)}</span></td><td>${pct(x.depreciation_rate)}</td><td>${esc(x.sample_size??'미확보')}</td></tr>`).join('');
     document.querySelectorAll('#rankingBody .clickable-row').forEach(r=>r.onclick=()=>{const v=(window.VEHICLES||[]).find?.(x=>x.brand===r.dataset.brand&&x.model===r.dataset.model);if(v&&typeof window.openDetail==='function')window.openDetail(v.brand,v.model,v.generation_code||v.generation);});
   }
   filter.addEventListener('change',()=>setTimeout(render,0));
   cat?.addEventListener('change',()=>setTimeout(render,0));
   render();
   window.CR_RANKING_CATALOG={brands,vehicleCount:vehicles.length,rankingCount:ranking.length};
 }catch(e){console.warn('ranking brand expansion',e)}
}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',()=>{setTimeout(boot,800)},{once:true});else setTimeout(boot,800);
})();