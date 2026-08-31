(()=>{
  const TOP5=[
    {rank:1,brand:'현대',model:'팰리세이드',gen:'LX2',year:2019,ret:'78.0%',dep:'22.0%'},
    {rank:2,brand:'현대',model:'싼타페',gen:'TM',year:2018,ret:'70.2%',dep:'29.8%'},
    {rank:3,brand:'기아',model:'니로',gen:'DE',year:2016,ret:'56.7%',dep:'43.3%'},
    {rank:4,brand:'현대',model:'아반떼',gen:'AD',year:2015,ret:'50.6%',dep:'49.4%'},
    {rank:5,brand:'기아',model:'스포티지',gen:'QL',year:2015,ret:'45.4%',dep:'54.6%'}
  ];
  const REVIEW_SETS={
    '팰리세이드':[
      ['공간 활용성이 강점','대형 SUV를 찾는 이용자라면 2·3열 공간과 적재공간을 우선 비교할 만합니다.'],
      ['가족용 선택에서 확인할 점','차체가 큰 만큼 주차 환경과 도심 운전 편의성도 함께 확인하는 것이 좋습니다.'],
      ['중고 구매 시 체크','연식별 편의사양과 주행거리, 사고·수리 이력을 함께 확인해야 실제 가치 판단이 정확해집니다.']
    ],
    '싼타페':[
      ['패밀리 SUV의 균형','공간, 승차감, 유지비를 균형 있게 비교하려는 이용자에게 대표적인 비교 대상입니다.'],
      ['연비와 유지비도 중요','같은 세대라도 엔진과 구동방식에 따라 연료비 차이가 있으므로 파워트레인을 구분해 보는 것이 좋습니다.'],
      ['중고차 상태 확인','소모품 교체 이력과 타이어, 하체 상태에 따라 체감 만족도가 크게 달라질 수 있습니다.']
    ],
    '니로':[
      ['도심 효율 중심 선택','연료비와 도심 주행 효율을 중시한다면 장점이 분명한 차종으로 비교할 수 있습니다.'],
      ['하이브리드 점검 포인트','배터리와 하이브리드 계통 보증, 정비 이력을 확인하면 중고 구매 판단에 도움이 됩니다.'],
      ['보유비용 관점','차량 가격뿐 아니라 연료비와 보험·소모품 비용을 함께 보면 장기 보유 판단이 쉬워집니다.']
    ],
    '아반떼':[
      ['유지비 부담이 비교적 낮은 편','준중형 세단은 보험료, 연료비, 소모품 비용까지 포함한 총보유비용 비교가 중요합니다.'],
      ['첫 차로 볼 때','구매가격뿐 아니라 주차 편의성과 연비, 정비 접근성을 함께 고려할 만합니다.'],
      ['연식별 차이 확인','같은 AD 세대라도 연식과 트림에 따라 안전·편의사양 차이가 있으므로 세부 확인이 필요합니다.']
    ],
    '스포티지':[
      ['실용 SUV 비교 대상','차체 크기와 적재공간, 연비를 함께 보는 소비자라면 주요 비교 후보가 됩니다.'],
      ['파워트레인별 차이','디젤·가솔린 등 엔진에 따라 정비비와 연료비 특성이 다르므로 구분해서 비교해야 합니다.'],
      ['중고 구매 체크','주행거리와 하체, 타이어, 사고이력 등 개별 차량 상태가 실제 만족도에 큰 영향을 줍니다.']
    ]
  };
  function esc(s){return String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));}
  function ensureTop5(){
    const body=document.getElementById('rankingBody'); if(!body) return;
    if(body.children.length>=5) return;
    body.innerHTML=TOP5.map(x=>`<tr class="clickable-row editorial-fallback"><td><strong>#${x.rank}</strong></td><td><strong>${x.brand} ${x.model}</strong><span class="muted-dark small">${x.gen}</span></td><td>${x.year}</td><td><span class="badge">${x.ret}</span></td><td>${x.dep}</td><td class="sample-col">참고</td></tr>`).join('');
  }
  function addEditorialPreview(){
    if(document.getElementById('editorialPreview')) return;
    const ranking=document.getElementById('ranking'); if(!ranking) return;
    const sec=document.createElement('section');
    sec.id='editorialPreview'; sec.className='section editorial-preview-section';
    const cards=[];
    TOP5.forEach(v=>REVIEW_SETS[v.model].forEach(([title,text],i)=>cards.push(`<article class="editorial-mini-card"><div class="editorial-mini-head"><strong>${esc(v.brand)} ${esc(v.model)} · ${v.year}</strong><span>초기 참고리뷰</span></div><h3>${esc(title)}</h3><p>${esc(text)}</p><small>CarRanking 편집 참고 · 실제 오너평점 미반영</small></article>`)));
    sec.innerHTML=`<div class="section-head"><div><p class="eyebrow">EDITORIAL REFERENCE REVIEW</p><h2>TOP5 초기 참고리뷰</h2><p class="muted-dark">실제 오너리뷰가 쌓이기 전 비교를 돕는 편집 참고내용입니다. 실제 오너평점·오너랭킹에는 반영하지 않습니다.</p></div></div><div class="editorial-review-grid">${cards.join('')}</div>`;
    ranking.insertAdjacentElement('afterend',sec);
  }
  function injectCss(){
    if(document.querySelector('link[href="home-fixes.css"]')) return;
    const l=document.createElement('link');l.rel='stylesheet';l.href='home-fixes.css';document.head.appendChild(l);
  }
  function run(){injectCss();ensureTop5();addEditorialPreview();setTimeout(ensureTop5,1200);setTimeout(ensureTop5,3000);}
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',run);else run();
})();