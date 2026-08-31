const FALLBACK_DATA=[{"rank":1,"brand":"현대","model":"팰리세이드","generation":"LX2","year":2019,"retention":78.0,"depreciation":22.0,"sample":134,"category":"대형 SUV"},{"rank":2,"brand":"현대","model":"싼타페","generation":"TM","year":2018,"retention":70.2,"depreciation":29.8,"sample":627,"category":"중형 SUV"},{"rank":3,"brand":"기아","model":"니로","generation":"DE","year":2016,"retention":56.7,"depreciation":43.3,"sample":null,"category":"SUV"},{"rank":4,"brand":"현대","model":"아반떼","generation":"AD","year":2015,"retention":50.6,"depreciation":49.4,"sample":333,"category":"준중형 세단"},{"rank":5,"brand":"기아","model":"스포티지","generation":"QL","year":2015,"retention":45.4,"depreciation":54.6,"sample":274,"category":"준중형 SUV"},{"rank":6,"brand":"현대","model":"투싼","generation":"TL","year":2015,"retention":42.8,"depreciation":57.2,"sample":229,"category":"준중형 SUV"},{"rank":7,"brand":"기아","model":"K5","generation":"JF","year":2015,"retention":38.7,"depreciation":61.3,"sample":558,"category":"중형 세단"},{"rank":8,"brand":"현대","model":"쏘나타","generation":"LF","year":2014,"retention":31.7,"depreciation":68.3,"sample":331,"category":"중형 세단"}];

const $=id=>document.getElementById(id);
const body=$('rankingBody'), brand=$('brandFilter'), category=$('categoryFilter');
let DATA=[...FALLBACK_DATA], VEHICLES=[], COMPARE=[], RATINGS=[];

function cfg(){return window.CARRANKING_CONFIG||{}}
async function api(view,query='select=*'){
  const c=cfg();
  if(!c.useSupabase||!c.supabaseUrl||!c.supabasePublishableKey) return [];
  const res=await fetch(`${c.supabaseUrl}/rest/v1/${view}?${query}`,{headers:{apikey:c.supabasePublishableKey,Authorization:`Bearer ${c.supabasePublishableKey}`}});
  if(!res.ok) throw new Error(`${view} HTTP ${res.status}`);
  return res.json();
}
function pct(v){return v==null?'정보 없음':`${(Number(v)*100).toFixed(1)}%`}
function won(v){return v==null?'정보 없음':`${Math.round(Number(v)/10000).toLocaleString()}만원`}
function mm(v){return v==null?'정보 없음':`${Number(v).toLocaleString()} mm`}
function esc(s){return String(s??'').replace(/[&<>'"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'}[c]))}
function vehicleLabel(v){return `${v.brand} ${v.model} ${v.generation_code||v.generation||''}`.trim()}

function fillRankingFilters(){
  brand.innerHTML='<option value="">전체 브랜드</option>'; category.innerHTML='<option value="">전체 차급</option>';
  [...new Set(DATA.map(x=>x.brand).filter(Boolean))].sort().forEach(v=>brand.insertAdjacentHTML('beforeend',`<option>${esc(v)}</option>`));
  [...new Set(DATA.map(x=>x.category).filter(Boolean))].sort().forEach(v=>category.insertAdjacentHTML('beforeend',`<option>${esc(v)}</option>`));
}
function renderHero(){
  const x=DATA[0]; if(!x)return;
  $('heroCard').innerHTML=`<div class="metric-label">가치보존율 1위</div><div class="car-name">${esc(x.brand)} ${esc(x.model)} ${esc(x.generation_code||x.generation||'')}</div><div class="big">${pct(x.retention_rate??x.retention/100)}</div><div class="muted">${esc(x.model_year??x.year??'-')}년식 · 참고 데이터</div>`;
}
function renderRanking(){
  const list=DATA.filter(x=>(!brand.value||x.brand===brand.value)&&(!category.value||x.category===category.value));
  body.innerHTML=list.map((x,i)=>`<tr class="clickable-row" data-brand="${esc(x.brand)}" data-model="${esc(x.model)}" data-generation="${esc(x.generation_code??x.generation??'')}"><td><strong>#${x.rank??i+1}</strong></td><td><strong>${esc(x.brand)} ${esc(x.model)}</strong><span class="muted-dark small">${esc(x.generation_code??x.generation??'')}</span></td><td>${esc(x.model_year??x.year??'-')}</td><td><span class="badge">${pct(x.retention_rate??x.retention/100)}</span></td><td>${pct(x.depreciation_rate??x.depreciation/100)}</td><td>${esc(x.sample_size??x.sample??'미확보')}</td></tr>`).join('');
  document.querySelectorAll('.clickable-row').forEach(r=>r.onclick=()=>openDetail(r.dataset.brand,r.dataset.model,r.dataset.generation));
}
function fillVehicleSelectors(){
  const ordered=[...VEHICLES].sort((a,b)=>vehicleLabel(a).localeCompare(vehicleLabel(b),'ko'));
  const options=ordered.map(v=>`<option value="${esc(v.generation_id)}">${esc(vehicleLabel(v))}</option>`).join('');
  $('compare1').innerHTML='<option value="">차량 1 선택</option>'+options;
  $('compare2').innerHTML='<option value="">차량 2 선택</option>'+options;
  $('compare3').innerHTML='<option value="">차량 3 선택 (선택)</option>'+options;
  const brands=[...new Set(ordered.map(v=>v.brand))].sort((a,b)=>a.localeCompare(b,'ko'));
  $('scoreBrand').innerHTML='<option value="">브랜드 선택</option>'+brands.map(v=>`<option>${esc(v)}</option>`).join('');
  updateScoreVehicles();
}
function updateScoreVehicles(){
  const b=$('scoreBrand').value;
  const list=VEHICLES.filter(v=>!b||v.brand===b).sort((a,b)=>vehicleLabel(a).localeCompare(vehicleLabel(b),'ko'));
  $('scoreVehicle').innerHTML='<option value="">모델/세대 선택</option>'+list.map(v=>`<option value="${esc(v.generation_id)}">${esc(vehicleLabel(v))}</option>`).join('');
}
function detailCard(label,value,sub=''){return `<div class="metric-card"><span>${esc(label)}</span><strong>${esc(value)}</strong>${sub?`<small>${esc(sub)}</small>`:''}</div>`}
function openDetail(b,m,g){
  const v=VEHICLES.find(x=>x.brand===b&&x.model===m&&(!g||x.generation_code===g||x.generation===g));
  if(!v)return;
  $('detailTitle').textContent=vehicleLabel(v);
  $('detailContent').innerHTML=[
    detailCard('차급',v.category||'정보 없음'),
    detailCard('생산 기간',`${v.start_year||'-'} ~ ${v.current?'현재':v.end_year||'-'}`),
    detailCard('기준 연식',v.model_year?`${v.model_year}년식`:'정보 없음'),
    detailCard('신차 기준가',won(v.original_price_krw)),
    detailCard('중고 기준가',won(v.used_price_krw)),
    detailCard('가치보존율',pct(v.retention_rate),v.sample_size?`표본 ${v.sample_size}`:'표본 미확보'),
    detailCard('감가율',pct(v.depreciation_rate)),
    detailCard('데이터 신뢰도',v.confidence||'정보 없음')
  ].join('');
  $('vehicleDetail').classList.remove('hidden'); $('vehicleDetail').scrollIntoView({behavior:'smooth',block:'start'});
}
function renderComparison(ids){
  const rows=ids.map(id=>COMPARE.find(v=>String(v.generation_id)===String(id))).filter(Boolean);
  if(rows.length<2){$('compareResult').innerHTML='<p class="notice">비교할 차량을 2대 이상 선택해 주세요.</p>';return}
  const metrics=[['차급',v=>v.category||'정보 없음'],['전장',v=>mm(v.length_mm)],['전폭',v=>mm(v.width_mm)],['전고',v=>mm(v.height_mm)],['휠베이스',v=>mm(v.wheelbase_mm)],['복합 효율',v=>v.combined_efficiency==null?'정보 없음':String(v.combined_efficiency)],['가치보존율',v=>pct(v.retention_rate)],['감가율',v=>pct(v.depreciation_rate)],['신뢰도',v=>v.confidence||'정보 없음']];
  $('compareResult').innerHTML=`<div class="table-wrap"><table class="compare-table"><thead><tr><th>항목</th>${rows.map(v=>`<th>${esc(vehicleLabel(v))}</th>`).join('')}</tr></thead><tbody>${metrics.map(([n,f])=>`<tr><th>${n}</th>${rows.map(v=>`<td>${esc(f(v))}</td>`).join('')}</tr>`).join('')}</tbody></table></div><p class="footnote">※ 확보되지 않은 제원은 ‘정보 없음’으로 표시하며 임의 추정하지 않습니다.</p>`;
}
function quickCompare(pair){
  const names=pair.split('|');
  const found=names.map(name=>COMPARE.find(v=>v.model===name)).filter(Boolean);
  if(found.length<2){$('compareResult').innerHTML='<p class="notice">현재 DB에서 해당 비교 조합의 세대 데이터를 충분히 찾지 못했습니다.</p>';return}
  $('compare1').value=found[0].generation_id; $('compare2').value=found[1].generation_id; $('compare3').value='';
  renderComparison(found.map(v=>v.generation_id)); $('compareResult').scrollIntoView({behavior:'smooth',block:'center'});
}
function showScore(){
  const id=$('scoreVehicle').value; const v=VEHICLES.find(x=>String(x.generation_id)===String(id));
  if(!v){$('scoreResult').innerHTML='<p class="notice">차량을 선택해 주세요.</p>';return}
  const r=RATINGS.find(x=>String(x.generation_id)===String(id));
  const owner=r&&Number(r.rating_count)>0?`${Number(r.overall_score).toFixed(2)} / 5`:'평가 데이터 부족';
  $('scoreResult').innerHTML=`<div class="score-summary"><strong>${esc(vehicleLabel(v))}</strong><span>가치보존율 ${pct(v.retention_rate)}</span><span>오너 종합평점 ${esc(owner)}</span>${v.model_year?`<span>${v.model_year}년식 기준</span>`:''}</div>`;
}
async function load(){
  try{
    const [ranking,vehicles,compare,ratings]=await Promise.all([
      api('web_value_ranking','select=*&order=retention_rate.desc'),
      api('web_vehicle_detail','select=*&order=brand.asc,model.asc,start_year.desc'),
      api('web_compare_base','select=*&order=brand.asc,model.asc'),
      api('web_rating_summary','select=*')
    ]);
    if(Array.isArray(ranking)&&ranking.length) DATA=ranking;
    if(Array.isArray(vehicles)) VEHICLES=vehicles;
    if(Array.isArray(compare)) COMPARE=compare;
    if(Array.isArray(ratings)) RATINGS=ratings;
  }catch(err){console.warn('Supabase unavailable; fallback ranking remains active.',err)}
  renderHero(); fillRankingFilters(); renderRanking(); fillVehicleSelectors();
}
brand.onchange=renderRanking; category.onchange=renderRanking;
$('closeDetail').onclick=()=>$('vehicleDetail').classList.add('hidden');
$('scoreBrand').onchange=updateScoreVehicles; $('scoreBtn').onclick=showScore;
$('compareBtn').onclick=()=>renderComparison([$('compare1').value,$('compare2').value,$('compare3').value].filter(Boolean));
document.querySelectorAll('[data-pair]').forEach(b=>b.onclick=()=>quickCompare(b.dataset.pair));
load();
