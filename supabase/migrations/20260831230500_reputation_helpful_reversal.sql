begin;

create or replace function private.cr_helpful_reward()
returns trigger language plpgsql security definer
set search_path=public,private,pg_temp as $$
declare
  v_review_id uuid:=coalesce(new.review_id,old.review_id);
  v_actor uuid:=coalesce(new.user_id,old.user_id);
  v_owner uuid;
  v_count integer;
begin
  select user_id into v_owner from public.reviews where id=v_review_id;
  select count(*)::integer into v_count from public.review_helpful where review_id=v_review_id;
  update public.reviews set helpful_count=v_count where id=v_review_id;

  if tg_op='INSERT' and v_owner is not null then
    insert into public.point_events(user_id,source_type,source_id,points,reason)
    values(v_owner,'helpful',v_review_id::text||':'||v_actor::text,5,'helpful_received')
    on conflict do nothing;
  elsif tg_op='DELETE' and v_owner is not null then
    delete from public.point_events pe
    where pe.user_id=v_owner
      and pe.source_type='helpful'
      and pe.source_id=v_review_id::text||':'||v_actor::text
      and pe.reason='helpful_received';
  end if;

  perform private.cr_refresh_user(v_owner);
  return coalesce(new,old);
end;$$;

revoke all on function private.cr_helpful_reward() from public,anon,authenticated;

delete from public.point_events pe
where pe.source_type='helpful'
  and pe.reason='helpful_received'
  and not exists (
    select 1 from public.review_helpful h
    where pe.source_id=h.review_id::text||':'||h.user_id::text
  );

do $$ declare u record; begin
  for u in select user_id from public.profiles loop
    perform private.cr_refresh_user(u.user_id);
  end loop;
end $$;

commit;