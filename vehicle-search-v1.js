/* CarRanking vehicle search v1 */
(()=>{
'use strict';
const C=window.CARRANKING_CONFIG||{};
const BASE=String(C.supabaseUrl||'').replace(/\/+$/,''),KEY=C.supabasePublishableKey||'';
const esc=s=>String(s??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));
let rows=[];
function install(){
 const hero=document.querySelector('.hero');if(!hero||document.getElementById('crVehicleSearch'))return;
 const style=document.createElement('style');style.textContent='.cr-search{max-width:1160px;margin:-16px auto 34px;padding:0 20px}.cr-search-box{position:relative;background:#fff;border:1px solid #dbe3ee;border-radius:16px;padding:14px;box-shadow:0 10px 28px rgba(15,23,42,.08)}.cr-search-row{display:flex;gap:8px}.cr-search-row input{flex:1;min-width:0;border:1px solid #cbd5e1;border-radius:11px;padding:12px 14px;font-size:16px}.cr-search-results{display:grid;gap:6px;margin-top:8px}.cr-search-result{width:100%;border:0;border-radius:10px;background:#f8fafc;padding:10px 12px;text-align:left;cursor:pointer}.cr-search-result:hover{background:#eaf2ff}.cr-search-empty{padding:10px 4px;color:#64748b;font-size:14px}@media(max-width:700px){.cr-search{margin-top:0;padding:0 14px}.cr-search-row{flex-direction:column}}';document.head.appendChild(style);
 const box=document.createElement('section');box.id='crVehicleSearch';box.className='cr-search';box.setAttribute('aria-label','차량 검색');box.innerHTML='<div class="cr-search-box"><div class="cr-search-row"><input id="crVehicleSearchInput" type="search" placeholder="차량명 검색 (예: G80, 쏘렌토)" autocomplete="off"><button class="btn primary" id="crVehicleSearchButton" type="button">검색</button></div><div id="crVehicleSearchResults" class="cr-search-results" aria-live="polite"></div></div>';
 hero.insertAdjacentElement('afterend',box);
 document.getElementById('crVehicleSearchButton').onclick=search;
 document.getElementById('crVehicleSearchInput').addEventListener('keydown',e=>{if(e.key==='Enter'){e.preventDefault();search()}});
}
async function load(){
 try{const r=await fetch(`${BASE}/rest/v1/web_search_index?select=*&order=brand.asc,model.asc`,{headers:{apikey:KEY,Authorization:`Bearer ${KEY}`},cache:'no-store'});if(!r.ok)throw new Error('HTTP '+r.status);rows=await r.json()}catch(e){console.warn('vehicle search unavailable',e)}
}
function search(){
 const input=document.getElementById('crVehicleSearchInput'),out=document.getElementById('crVehicleSearchResults');if(!input||!out)return;
 const q=input.value.trim().toLocaleLowerCase('ko-KR');if(!q){out.innerHTML='<div class="cr-search-empty">검색할 차량명을 입력해 주세요.</div>';return}
 const found=rows.filter(x=>String(x.search_text||[x.brand,x.model,x.generation,x.generation_code].join(' ')).toLocaleLowerCase('ko-KR').includes(q)).slice(0,12);
 out.innerHTML=found.length?found.map((x,i)=>`<button class="cr-search-result" type="button" data-i="${i}"><strong>${esc(x.brand)} ${esc(x.model)}</strong> <span>${esc(x.generation_code||x.generation||'')}</span></button>`).join(''):'<div class="cr-search-empty">검색 결과가 없습니다. 차량명 일부만 입력해 보세요.</div>';
 out.querySelectorAll('[data-i]').forEach(b=>b.onclick=()=>{const x=found[Number(b.dataset.i)];window.CARRANKING_OPEN_DETAIL?.(x.brand,x.model,x.generation_code||x.generation)});
}
async function boot(){install();await load()}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',boot,{once:true});else boot();
})();
