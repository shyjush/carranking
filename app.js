const FALLBACK_DATA=[{"rank": 1, "brand": "현대", "model": "팰리세이드", "generation": "LX2", "year": 2019, "retention": 78.0, "depreciation": 22.0, "sample": 134, "category": "대형 SUV"}, {"rank": 2, "brand": "현대", "model": "싼타페", "generation": "TM", "year": 2018, "retention": 70.2, "depreciation": 29.8, "sample": 627, "category": "중형 SUV"}, {"rank": 3, "brand": "기아", "model": "니로", "generation": "DE", "year": 2016, "retention": 56.7, "depreciation": 43.3, "sample": null, "category": "SUV"}, {"rank": 4, "brand": "현대", "model": "아반떼", "generation": "AD", "year": 2015, "retention": 50.6, "depreciation": 49.4, "sample": 333, "category": "준중형 세단"}, {"rank": 5, "brand": "기아", "model": "스포티지", "generation": "QL", "year": 2015, "retention": 45.4, "depreciation": 54.6, "sample": 274, "category": "준중형 SUV"}, {"rank": 6, "brand": "현대", "model": "투싼", "generation": "TL", "year": 2015, "retention": 42.8, "depreciation": 57.2, "sample": 229, "category": "준중형 SUV"}, {"rank": 7, "brand": "기아", "model": "K5", "generation": "JF", "year": 2015, "retention": 38.7, "depreciation": 61.3, "sample": 558, "category": "중형 세단"}, {"rank": 8, "brand": "현대", "model": "쏘나타", "generation": "LF", "year": 2014, "retention": 31.7, "depreciation": 68.3, "sample": 331, "category": "중형 세단"}];

const body=document.getElementById('rankingBody');
const brand=document.getElementById('brandFilter');
const category=document.getElementById('categoryFilter');

let DATA=[...FALLBACK_DATA];

function fillFilters() {
  brand.innerHTML='<option value="">전체 브랜드</option>';
  category.innerHTML='<option value="">전체 차급</option>';
  [...new Set(DATA.map(x=>x.brand).filter(Boolean))].forEach(v=>brand.insertAdjacentHTML('beforeend',`<option>${v}</option>`));
  [...new Set(DATA.map(x=>x.category).filter(Boolean))].forEach(v=>category.insertAdjacentHTML('beforeend',`<option>${v}</option>`));
}

function render() {
  const list=DATA.filter(x=>(!brand.value||x.brand===brand.value)&&(!category.value||x.category===category.value));
  body.innerHTML=list.map((x,i)=>`<tr>
    <td><strong>#${x.rank ?? i+1}</strong></td>
    <td><strong>${x.brand} ${x.model}</strong><span class="muted">${x.generation_code ?? x.generation ?? ''}</span></td>
    <td>${x.model_year ?? x.year ?? '-'}</td>
    <td><span class="badge">${((x.retention_rate ?? x.retention/100)*100).toFixed(1)}%</span></td>
    <td>${((x.depreciation_rate ?? x.depreciation/100)*100).toFixed(1)}%</td>
    <td>${x.sample_size ?? x.sample ?? '미확보'}</td>
  </tr>`).join('');
}

async function tryLoadSupabase() {
  const cfg=window.CARRANKING_CONFIG||{};
  if(!cfg.useSupabase || !cfg.supabaseUrl || !cfg.supabasePublishableKey) return;
  try {
    const res=await fetch(`${cfg.supabaseUrl}/rest/v1/web_value_ranking?select=*&order=retention_rate.desc`, {
      headers: {
        apikey: cfg.supabasePublishableKey,
        Authorization: `Bearer ${cfg.supabasePublishableKey}`
      }
    });
    if(!res.ok) throw new Error(`Supabase HTTP ${res.status}`);
    const rows=await res.json();
    if(Array.isArray(rows) && rows.length) DATA=rows;
  } catch(err) {
    console.warn("Supabase unavailable; using fallback ranking data.", err);
  }
}

brand.onchange=render;
category.onchange=render;

(async()=>{
  await tryLoadSupabase();
  fillFilters();
  render();
})();
