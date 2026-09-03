/* CarRanking account and share controls v5 */
(()=>{'use strict';
const C=window.CARRANKING_CONFIG||{},BASE=String(C.supabaseUrl||'').replace(/\/+$/,''),KEY=C.supabasePublishableKey||'';
const ACCESS='carranking_access_token',REFRESH='carranking_refresh_token',REMEMBER='carranking_remember_login',EMAIL='carranking_saved_email';
const $=s=>document.querySelector(s);
let currentUser=null;
function store(){return localStorage.getItem(REMEMBER)==='1'?localStorage:sessionStorage}
function getAccess(){return localStorage.getItem(ACCESS)||sessionStorage.getItem(ACCESS)||''}
function getRefresh(){return localStorage.getItem(REFRESH)||sessionStorage.getItem(REFRESH)||''}
function clearTokens(){[localStorage,sessionStorage].forEach(s=>{s.removeItem(ACCESS);s.removeItem(REFRESH)})}
function saveSession(d,remember){
 clearTokens();
 const s=remember?localStorage:sessionStorage;
 if(d?.access_token)s.setItem(ACCESS,d.access_token);
 if(d?.refresh_token)s.setItem(REFRESH,d.refresh_token);
 if(remember)localStorage.setItem(REMEMBER,'1');else localStorage.removeItem(REMEMBER);
}
async function auth(path,options={},tokenOverride=null){
 const token=tokenOverride===null?getAccess():tokenOverride;
 const headers={apikey:KEY,'Content-Type':'application/json',...(options.headers||{})};
 if(token)headers.Authorization='Bearer '+token;
 const r=await fetch(BASE+'/auth/v1/'+path,{...options,headers});
 const t=await r.text();let x={};try{x=t?JSON.parse(t):{}}catch(_){}
 if(!r.ok){const e=new Error(x.message||x.msg||t||'인증 오류');e.status=r.status;throw e}
 return x;
}
async function refreshSession(){
 const rt=getRefresh();if(!rt)throw new Error('refresh token 없음');
 const d=await auth('token?grant_type=refresh_token',{method:'POST',body:JSON.stringify({refresh_token:rt})},'');
 saveSession(d,localStorage.getItem(REMEMBER)==='1');
 return d;
}
function syncAccountButton(){const b=$('#crAccountBtn');if(!b)return;b.textContent=currentUser?'MY':'로그인·간편가입';b.dataset.mode=currentUser?'my':'login'}
function showPanel(my){$('#crLoginPanel')?.classList.toggle('hidden',my);$('#crMyPanel')?.classList.toggle('hidden',!my);if(my)$('#crMyEmail').textContent=currentUser?.email||'로그인 사용자'}
function open(mode){const my=mode==='my'&&currentUser;showPanel(Boolean(my));$('#crAuthModal')?.classList.remove('hidden');setTimeout(()=>$(my?'#crCurrentPassword':'#crAuthEmail')?.focus(),30)}
function close(){$('#crAuthModal')?.classList.add('hidden')}
function installRememberUI(){
 const panel=$('#crLoginPanel');if(!panel||$('#crRememberLogin'))return;
 const password=$('#crAuthPassword');const label=password?.closest('label');if(!label)return;
 const wrap=document.createElement('label');wrap.style.cssText='display:flex;align-items:center;gap:9px;margin:10px 0 4px;font-size:14px;cursor:pointer';
 wrap.innerHTML='<input id="crRememberLogin" type="checkbox" style="width:18px;height:18px"> <span><b>아이디 저장 · 로그인 상태 유지</b><br><small style="font-weight:400;color:#6b7280">비밀번호 원문은 저장하지 않고 안전한 로그인 토큰을 유지합니다.</small></span>';
 label.insertAdjacentElement('afterend',wrap);
 const remembered=localStorage.getItem(REMEMBER)==='1';$('#crRememberLogin').checked=remembered;
 const saved=localStorage.getItem(EMAIL);if(saved&&$('#crAuthEmail'))$('#crAuthEmail').value=saved;
}
async function restore(){
 if(!getAccess()&&!getRefresh()){syncAccountButton();return}
 try{currentUser=await auth('user',{method:'GET'})}
 catch(_){
  try{const d=await refreshSession();currentUser=d.user||await auth('user',{method:'GET'})}
  catch(__){clearTokens();currentUser=null}
 }
 syncAccountButton();
}
async function submit(){
 const email=$('#crAuthEmail')?.value.trim().toLowerCase(),password=$('#crAuthPassword')?.value||'',b=$('#crAuthSubmit'),remember=Boolean($('#crRememberLogin')?.checked);
 if(!email||!email.includes('@'))return alert('이메일 주소를 확인해주세요.');
 if(password.length<8)return alert('비밀번호는 8자 이상 입력해주세요.');
 b.disabled=true;b.textContent='확인 중…';
 try{
  try{
   const d=await auth('token?grant_type=password',{method:'POST',body:JSON.stringify({email,password})},'');
   if(d.access_token){saveSession(d,remember);if(remember)localStorage.setItem(EMAIL,email);else localStorage.removeItem(EMAIL);currentUser=d.user||await auth('user',{method:'GET'});syncAccountButton();close();alert(remember?'로그인되었습니다. 다음 접속부터 로그인 상태를 유지합니다.':'로그인되었습니다.');return}
  }catch(loginError){if(!/invalid login credentials/i.test(loginError.message))throw loginError}
  const d=await auth('signup',{method:'POST',body:JSON.stringify({email,password,data:{display_name:'오너'}})},'');
  if(d.access_token){saveSession(d,remember);if(remember)localStorage.setItem(EMAIL,email);currentUser=d.user||await auth('user',{method:'GET'});syncAccountButton();close();alert('간편회원가입과 로그인이 완료되었습니다.');return}
  const isNew=Array.isArray(d.user?.identities)&&d.user.identities.length>0;
  alert(isNew?'가입 확인 메일을 보냈습니다. 이메일 확인 후 같은 화면에서 로그인해주세요.':'등록된 이메일입니다. 비밀번호가 틀렸다면 비밀번호 재설정을 이용해주세요.');
 }catch(e){alert(e.message==='email rate limit exceeded'?'이메일 발송 한도를 초과했습니다. 잠시 후 다시 시도해주세요.':'로그인·가입 오류: '+e.message)}
 finally{b.disabled=false;b.textContent='로그인 · 간편회원가입'}
}
async function changePassword(){
 const current=$('#crCurrentPassword')?.value||'',next=$('#crNewPassword')?.value||'',confirm=$('#crConfirmPassword')?.value||'',b=$('#crChangePassword');
 if(!currentUser)return alert('로그인 후 이용해주세요.');if(current.length<8)return alert('현재 비밀번호를 입력해주세요.');if(next.length<8)return alert('새 비밀번호는 8자 이상 입력해주세요.');if(next!==confirm)return alert('새 비밀번호가 서로 일치하지 않습니다.');if(current===next)return alert('현재 비밀번호와 다른 비밀번호를 입력해주세요.');
 b.disabled=true;b.textContent='변경 중…';
 try{await auth('user',{method:'PUT',body:JSON.stringify({email:currentUser.email,current_password:current,password:next})});$('#crCurrentPassword').value='';$('#crNewPassword').value='';$('#crConfirmPassword').value='';alert('비밀번호가 변경되었습니다.')}
 catch(e){alert('비밀번호 변경 오류: '+(/invalid login credentials/i.test(e.message)?'현재 비밀번호가 올바르지 않습니다.':e.message))}
 finally{b.disabled=false;b.textContent='비밀번호 변경'}
}
async function logout(){try{await auth('logout',{method:'POST'})}catch(_){}clearTokens();currentUser=null;syncAccountButton();close();alert('로그아웃되었습니다.')}
async function resetPassword(){const email=$('#crAuthEmail')?.value.trim();if(!email)return alert('이메일을 먼저 입력해주세요.');try{await auth('recover?redirect_to='+encodeURIComponent('https://carranking.kr/'),{method:'POST',body:JSON.stringify({email})},'');alert('비밀번호 재설정 메일을 보냈습니다.')}catch(e){alert(e.message==='email rate limit exceeded'?'이메일 발송 한도를 초과했습니다. 잠시 후 다시 시도해주세요.':'재설정 메일 오류: '+e.message)}}
function share(){const text=encodeURIComponent('CarRanking - 자동차 순위·가치보존율·오너평점\n'+location.href),route=encodeURIComponent(location.hostname||'carranking.kr');if(/Android|iPhone|iPad/i.test(navigator.userAgent)){location.href='bandapp://create/post?text='+text+'&route='+route;setTimeout(()=>window.open('https://band.us/plugin/share?body='+text+'&route='+route,'share_band','width=410,height=540,resizable=yes'),700)}else window.open('https://band.us/plugin/share?body='+text+'&route='+route,'share_band','width=410,height=540,resizable=yes')}
document.addEventListener('DOMContentLoaded',()=>{installRememberUI();restore();document.querySelectorAll('.cr-auth-open').forEach(b=>b.onclick=()=>open(b.dataset.mode));document.querySelectorAll('[data-cr-close]').forEach(b=>b.onclick=close);$('#crAuthSubmit').onclick=submit;$('#crAuthReset').onclick=resetPassword;$('#crChangePassword').onclick=changePassword;$('#crLogout').onclick=logout;['crAuthEmail','crAuthPassword'].forEach(id=>$('#'+id).onkeydown=e=>{if(e.key==='Enter')submit()});['crCurrentPassword','crNewPassword','crConfirmPassword'].forEach(id=>$('#'+id).onkeydown=e=>{if(e.key==='Enter')changePassword()});$('#crBandShare').onclick=share;document.addEventListener('keydown',e=>{if(e.key==='Escape')close()})});
})();