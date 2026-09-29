(()=>{'use strict';
const C=window.CARRANKING_CONFIG||{},BASE=String(C.supabaseUrl||'').replace(/\/+$/,''),KEY=C.supabasePublishableKey||'';
const ACCESS='carranking_access_token';
const $=s=>document.querySelector(s);
const esc=s=>String(s??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));
const normalizeBody=s=>String(s??'').split(String.fromCharCode(92)+'n').join(String.fromCharCode(10));
const token=()=>localStorage.getItem(ACCESS)||sessionStorage.getItem(ACCESS)||'';
function headers(auth=false){const h={apikey:KEY};if(auth&&token())h.Authorization='Bearer '+token();return h}
function fmtDate(x){try{return new Intl.DateTimeFormat('ko-KR',{year:'numeric',month:'2-digit',day:'2-digit',hour:'2-digit',minute:'2-digit'}).format(new Date(x))}catch(_){return x||''}}
async function loadPosts(){
 const box=$('#communityList');box.innerHTML='<div class="empty">게시글을 불러오는 중입니다.</div>';
 try{
  const r=await fetch(BASE+'/rest/v1/community_posts?select=id,author_name,title,body,post_type,is_system,created_at&is_published=eq.true&order=created_at.desc&limit=100',{headers:headers(),cache:'no-store'});
  if(!r.ok)throw new Error('HTTP '+r.status);
  const rows=await r.json();
  if(!rows.length){box.innerHTML='<div class="empty">아직 게시글이 없습니다.</div>';return}
  box.innerHTML=rows.map(x=>'<article class="community-post'+(x.is_system?' system-post':'')+'">'+
   '<div class="community-post-meta"><span>'+(x.is_system?'오늘의 성인유머':'자유글')+'</span><span>'+esc(x.author_name)+' · '+esc(fmtDate(x.created_at))+'</span></div>'+
   '<h3>'+esc(x.title)+'</h3><p>'+esc(normalizeBody(x.body))+'</p></article>').join('');
 }catch(e){box.innerHTML='<div class="empty">게시글을 불러오지 못했습니다.</div>';console.warn(e)}
}
async function currentUser(){
 if(!token())return null;
 const r=await fetch(BASE+'/auth/v1/user',{headers:{apikey:KEY,Authorization:'Bearer '+token()}});
 if(!r.ok)return null;return r.json();
}
async function submit(e){
 e.preventDefault();const b=$('#communitySubmit'),m=$('#communityMessage'),title=$('#communityTitle').value.trim(),body=$('#communityBody').value.trim();
 if(!title||!body)return;
 const user=await currentUser();
 if(!user){m.textContent='로그인 후 글을 등록할 수 있습니다.';document.querySelector('#crAccountBtn')?.click();return}
 b.disabled=true;m.textContent='등록 중…';
 try{
   const name=(user.user_metadata?.display_name||user.email?.split('@')[0]||'회원').slice(0,40);
   const r=await fetch(BASE+'/rest/v1/community_posts',{method:'POST',headers:{...headers(true),'Content-Type':'application/json',Prefer:'return=minimal'},body:JSON.stringify({author_user_id:user.id,author_name:name,title,body,post_type:'free',is_system:false,is_published:true})});
   if(!r.ok){const t=await r.text();throw new Error(t)}
   $('#communityForm').reset();m.textContent='등록되었습니다.';await loadPosts();setComposer(false);
 }catch(e){console.error(e);m.textContent='등록하지 못했습니다. 다시 시도해 주세요.'}
 finally{b.disabled=false}
}
function setComposer(open){
 const panel=$('#communityComposePanel'),toggle=$('#communityComposeToggle');
 if(!panel||!toggle)return;
 panel.classList.toggle('hidden',!open);
 toggle.setAttribute('aria-expanded',open?'true':'false');
 toggle.textContent=open?'글쓰기 닫기':'새 글 쓰기';
 if(open)setTimeout(()=>$('#communityTitle')?.focus(),30);
}
document.addEventListener('DOMContentLoaded',()=>{
 loadPosts();
 $('#communityRefresh').onclick=loadPosts;
 $('#communityComposeToggle').onclick=()=>setComposer($('#communityComposePanel').classList.contains('hidden'));
 $('#communityComposeClose').onclick=()=>setComposer(false);
 $('#communityForm').addEventListener('submit',submit);
});
})();