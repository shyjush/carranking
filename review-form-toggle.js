'use strict';
(function(){
 const button=document.getElementById('reviewFormToggle'),form=document.getElementById('reviewForm');
 if(!button||!form)return;
 form.hidden=true;
 button.setAttribute('aria-expanded','false');
 button.addEventListener('click',()=>{
  const open=form.hidden;
  form.hidden=!open;
  button.setAttribute('aria-expanded',String(open));
 });
})();