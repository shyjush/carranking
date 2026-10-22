(()=>{'use strict';
const cfg=window.CARRANKING_CONFIG||{},base=String(cfg.supabaseUrl||'').replace(/\/$/,'');
const apiKey=cfg.supabasePublishableKey,token=()=>localStorage.getItem('carranking_access_token')||sessionStorage.getItem('carranking_access_token')||'';
const h=auth=>({apikey:apiKey,...(auth&&token()?{Authorization:'Bearer '+token()}:{})});
const safeText=(el,text)=>{el.textContent=String(text??'');return el};
const elt=(name,cls,txt)=>{let x=document.createElement(name);if(cls)x.className=cls;if(txt!==undefined)safeText(x,txt);return x};
function makeCommentPanel(type,id){
 const root=elt('section','member-discussion');
 const trigger=elt('button','member-discussion-toggle','댓글·답글 보기');trigger.type='button';trigger.setAttribute('aria-expanded','false');
 const content=elt('div','member-discussion-content');content.hidden=true;
 const list=elt('div','member-comment-list');
 const info=elt('p','member-comment-info');
 const form=elt('form','member-comment-form'),textarea=elt('textarea');textarea.placeholder='댓글을 입력하세요 (회원 로그인 필요)';textarea.maxLength=1500;textarea.required=true;textarea.rows=2;
 const submit=elt('button','member-comment-submit','댓글 등록');submit.type='submit';
 form.append(textarea,submit);content.append(info,list,form);root.append(trigger,content);
 let loaded=false;
 async function load(){
  info.textContent='댓글을 불러오는 중입니다.';
  try{
   const query=new URLSearchParams({select:'id,parent_id,author_name,author_user_id,body,created_at,is_deleted',target_type:'eq.'+type,target_id:'eq.'+id,order:'created_at.asc',limit:'300'});
   const res=await fetch(base+'/rest/v1/member_comments?'+query,{headers:h(false),cache:'no-store'});
   if(!res.ok)throw Error('HTTP '+res.status);
   const rows=await res.json();list.replaceChildren();
   const nodes=new Map();const current=[];
   rows.forEach(c=>{
    const box=elt('div','member-comment'+(c.parent_id?' member-comment-reply':''));
    const head=elt('div','member-comment-head',(c.author_name||'회원')+' · '+new Date(c.created_at).toLocaleDateString('ko-KR'));
    const body=elt('p','',c.is_deleted?'삭제된 댓글입니다.':c.body);
    box.append(head,body);
    if(!c.is_deleted){
     const reply=elt('button','member-reply-button','답글');reply.type='button';reply.onclick=()=>{
      const old=box.querySelector('.member-inline-reply');if(old){old.remove();return;}
      const f=elt('form','member-inline-reply');const t=elt('textarea');t.required=true;t.maxLength=1500;t.rows=2;t.placeholder='답글을 입력하세요';
      const b=elt('button','','답글 등록');b.type='submit';f.append(t,b);f.onsubmit=async e=>{e.preventDefault();await send(t.value,c.id,b)};box.append(f);t.focus();
     };box.append(reply);
    }
    nodes.set(c.id,box);current.push([c,box]);
   });
   current.forEach(([c,box])=>{const parent=nodes.get(c.parent_id);(parent||list).append(box)});
   info.textContent=rows.length?'댓글 '+rows.length+'개':'아직 댓글이 없습니다.';
   trigger.textContent='댓글·답글 '+rows.length+'개 '+(content.hidden?'보기':'접기');
   loaded=true;
  }catch(e){info.textContent='댓글을 불러오지 못했습니다.';console.warn('member comments',e)}
 }
 async function send(body,parent,button){
  const value=String(body||'').trim();if(!value)return;
  button.disabled=true;
  try{
   if(!token())throw Error('회원 로그인 후 댓글을 작성할 수 있습니다.');
   const auth=await fetch(base+'/auth/v1/user',{headers:{apikey:apiKey,Authorization:'Bearer '+token()}});
   if(!auth.ok)throw Error('로그인이 만료됐습니다. 다시 로그인해 주세요.');
   const user=await auth.json();
   const author_name=String(user.user_metadata?.display_name||user.email?.split('@')[0]||'회원').slice(0,40);
   const res=await fetch(base+'/rest/v1/member_comments',{method:'POST',headers:{...h(true),'Content-Type':'application/json',Prefer:'return=minimal'},body:JSON.stringify({target_type:type,target_id:id,parent_id:parent||null,author_user_id:user.id,author_name,body:value})});
   if(!res.ok)throw Error('댓글 저장 실패: '+res.status);
   textarea.value='';await load();
  }catch(e){info.textContent=e.message;document.querySelector('#crAccountBtn')?.click()}finally{button.disabled=false}
 }
 form.onsubmit=async e=>{e.preventDefault();await send(textarea.value,null,submit)};
 trigger.onclick=()=>{content.hidden=!content.hidden;trigger.setAttribute('aria-expanded',String(!content.hidden));if(!content.hidden){load()}else{trigger.textContent='댓글·답글 보기'}};
 return root;
}
window.CARRANKING_MEMBER_DISCUSSIONS={makeCommentPanel};
})();