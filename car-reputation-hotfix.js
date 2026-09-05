/* CarRanking member review submit ordering hotfix */
(()=>{
'use strict';
const TOKEN_KEY='carranking_access_token';
// car-reputation.js의 document capture 핸들러가 먼저 회원 RPC를 시작한다.
// 여기서는 같은 capture 단계에서 즉시 기본 submit/기존 app.js submit 전파를 차단해
// 회원 리뷰가 익명 visitor 리뷰로 중복 등록되는 것을 방지한다.
document.addEventListener('submit',e=>{
  if(e.target?.id!=='reviewForm')return;
  if(!localStorage.getItem(TOKEN_KEY))return;
  e.preventDefault();
  e.stopImmediatePropagation();
},true);

// 가치보존 랭킹/상단 카드/BEST·WORST 렌더링은 home-fixes.js에서 단일 관리한다.
})();
