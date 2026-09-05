(()=>{
'use strict';
function addSeoHub(){
  if(document.getElementById('seoDiscovery'))return;
  const main=document.querySelector('main');
  if(!main)return;
  const sec=document.createElement('section');
  sec.id='seoDiscovery';
  sec.className='section';
  sec.innerHTML=`<div class="section-head"><div><p class="eyebrow">CARRANKING GUIDE</p><h2>자동차 추천·평가 바로가기</h2><p class="muted-dark">자동차 추천, 자동차 평가, 가치보존율·감가율, 실제 오너평가를 기준별로 확인하세요.</p></div></div><div class="grid popular-grid"><article class="compare-card"><strong>자동차 추천</strong><span>가치보존·감가·오너평가 기준</span><a class="btn" href="/recommend.html">자동차 추천 보기</a></article><article class="compare-card"><strong>자동차 평가</strong><span>연식보정·현재가치·등급 설명</span><a class="btn" href="/evaluation.html">자동차 평가 보기</a></article><article class="compare-card"><strong>자동차 순위</strong><span>연식보정 가치보존 랭킹</span><a class="btn" href="/ranking.html">자동차 순위 보기</a></article></div>`;
  const ranking=document.getElementById('ranking');
  if(ranking)ranking.insertAdjacentElement('beforebegin',sec); else main.prepend(sec);
}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',addSeoHub,{once:true});else addSeoHub();
})();
