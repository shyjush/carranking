/* CarRanking public ranking sync: specialist DB is authoritative */
(()=>{'use strict';
const PICKRANK_URL='https://umreaxukykowauxkauyd.supabase.co';
const PICKRANK_KEY='sb_publishable_QdAdkaQJNLf-9yY53_i_AA_EEjLl0gW';
const esc=s=>String(s??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));
const pct=v=>v==null?'정보 없음':(Number(v)*100).toFixed(1)+'%';
function parseIdentity(row){
 const meta=row.metadata||{},year=Number(meta.model_year)||Number(String(row.item_name||'').match(/(20\d{2})/)?.[1])||null;
 const named=String(row.item_name||'').match(/^The\s+20\d{2}\s+(.+)$/i);
 if(meta.manufacturer||meta.model||named){
  const brand=meta.manufacturer||String(row.region||'').split(/\s+/)[0]||'';
  return {brand,model:meta.model||named?.[1]||String(row.item_name||''),generation:meta.generation||'',year};
 }
 const label=String(row.item_name||'').replace(/\s+\d{4}년식\s*$/,'').trim();
 const parts=label.split(/\s+/);
 return {brand:parts.shift()||'',generation:parts.length>1?parts.pop():'',model:parts.join(' '),year};
}
function normalize(row){
 const id=parseIdentity(row),raw=row.metadata?.raw_score??(row.score==null?null:row.score/100),retention=raw==null?null:Number(raw);
 return {rank:Number(row.rank_no),brand:id.brand,model:id.model,generation_code:id.generation,
  model_year:id.year,retention_rate:retention,
  depreciation_rate:row.metadata?.depreciation_rate==null?(retention==null?null:1-retention):Number(row.metadata.depreciation_rate),
  sample_size:Number(row.review_count)||0,category:row.region||row.metadata?.category||'',
  data_as_of:row.data_as_of,external_key:row.external_key,pickrank_canonical:true};
}
async function pickrankRows(){
 const query='select=rank_no,score,review_count,data_as_of,item_name,region,metadata,external_key&category_slug=eq.car&order=rank_no.asc&limit=300';
 const r=await fetch(PICKRANK_URL+'/rest/v1/latest_published_rankings?'+query,{headers:{apikey:PICKRANK_KEY,Authorization:'Bearer '+PICKRANK_KEY},cache:'no-store'});
 if(!r.ok)throw new Error('PICKRANK HTTP '+r.status);
 const rows=await r.json();
 if(!Array.isArray(rows)||!rows.length)throw new Error('PICKRANK 공개 자동차 순위가 없습니다.');
 return rows.map(normalize);
}
async function localRows(){
 const C=window.CARRANKING_CONFIG||{},base=String(C.supabaseUrl||'').replace(/\/+$/,''),key=C.supabasePublishableKey||'';
 if(!base||!key)throw new Error('CarRanking fallback 설정이 없습니다.');
 const r=await fetch(base+'/rest/v1/web_value_ranking?select=*&order=retention_rate.desc',{headers:{apikey:key},cache:'no-store'});
 if(!r.ok)throw new Error('CarRanking fallback HTTP '+r.status);
 return r.json();
}
function render(rows,canonical){
 const body=document.getElementById('rankingBody'),hero=document.getElementById('heroCard');
 if(!body||!rows.length)return;
 window.CR_LIVE_RANKING=rows;window.CR_LIVE_RANKING_COUNT=rows.length;
 try{DATA=rows;fillRankingFilters();renderRanking();renderHero()}catch(_){
  body.innerHTML=rows.map((x,i)=>'<tr class="clickable-row" data-brand="'+esc(x.brand)+'" data-model="'+esc(x.model)+'" data-generation="'+esc(x.generation_code||x.generation||'')+'"><td><strong>#'+(x.rank??i+1)+'</strong></td><td><strong>'+esc(x.brand)+' '+esc(x.model)+'</strong><span class="muted-dark small">'+esc(x.generation_code||x.generation||'')+'</span></td><td>'+esc(x.model_year??'-')+'</td><td><span class="badge">'+pct(x.retention_rate)+'</span></td><td>'+pct(x.depreciation_rate)+'</td><td>'+esc(x.sample_size??'미확보')+'</td></tr>').join('');
 }
 body.querySelectorAll('.clickable-row').forEach(row=>row.onclick=()=>window.CARRANKING_OPEN_DETAIL?.(row.dataset.brand,row.dataset.model,row.dataset.generation));
 const top=rows[0],date=top?.data_as_of?new Intl.DateTimeFormat('ko-KR',{timeZone:'Asia/Seoul',year:'numeric',month:'numeric',day:'numeric'}).format(new Date(top.data_as_of)):'';
 if(hero&&top)hero.innerHTML='<div class="metric-label">가치보존율 1위</div><div class="car-name">'+esc(top.brand)+' '+esc(top.model)+' '+esc(top.generation_code||'')+'</div><div class="big">'+pct(top.retention_rate)+'</div><div class="muted">'+esc(top.model_year??'-')+'년식 · '+(canonical?'PICKRANK 중앙 확정 순위':'CarRanking 자체 순위')+(date?' · '+date+' 기준':'')+'</div>';
 document.documentElement.dataset.rankingRows=String(rows.length);
 document.documentElement.dataset.rankingSource=canonical?'pickrank':'carranking-fallback';
 const note=document.querySelector('#ranking .footnote');
 if(note)note.textContent=canonical
  ?'※ PICKRANK 중앙 DB에서 검증·확정한 자동차 가치보존율 순위 '+rows.length+'개를 동일하게 표시합니다.'
  :'※ CarRanking에서 검증한 자체 가치보존 순위를 표시합니다.';
}
async function load(){
 try{render(await localRows(),false)}
 catch(e){console.warn('CarRanking ranking unavailable.',e)}
}
function start(){load();setInterval(load,300000)}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',()=>setTimeout(start,1200),{once:true});else setTimeout(start,1200);
})();
