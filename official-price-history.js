'use strict';
(()=>{
 const input=document.getElementById('priceSearch'),year=document.getElementById('priceYear'),count=document.getElementById('priceCount'),rows=[...document.querySelectorAll('tbody tr')];
 const initialGeneration=new URLSearchParams(location.search).get('generation');let generation=initialGeneration;
 function filter(){const tokens=input.value.trim().toLowerCase().split(/\s+/).filter(Boolean);let shown=0;
  for(const row of rows){const visible=(!generation||row.dataset.generation===generation)&&(!year.value||row.dataset.year===year.value)&&tokens.every(t=>row.dataset.search.includes(t));row.hidden=!visible;if(visible)shown++;}
  count.textContent=`${shown}개 가격 표시 · 전체 ${rows.length}개${generation?' · 선택 세대만 표시':''}`;
 }
 input.addEventListener('input',filter);year.addEventListener('change',filter);document.getElementById('priceReset').addEventListener('click',()=>{generation=null;input.value='';year.value='';filter();});filter();
})();
