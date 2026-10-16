begin;

create schema if not exists private;

create or replace function private.cr_sync_external_source_primary_link()
returns trigger
language plpgsql
set search_path=public,private,pg_temp
as $$
begin
  if tg_op='UPDATE' and old.generation_id is distinct from new.generation_id then
    delete from public.external_review_source_vehicle_links
    where source_id=new.id
      and generation_id=old.generation_id
      and relation_role='subject';
  end if;

  insert into public.external_review_source_vehicle_links(source_id,generation_id,relation_role)
  values(new.id,new.generation_id,'subject')
  on conflict(source_id,generation_id) do update
  set relation_role=case
    when public.external_review_source_vehicle_links.relation_role='subject' then 'subject'
    else excluded.relation_role
  end;

  return new;
end;
$$;

drop trigger if exists cr_external_source_primary_link_trigger
  on public.external_review_sources;

create trigger cr_external_source_primary_link_trigger
after insert or update of generation_id
on public.external_review_sources
for each row
execute function private.cr_sync_external_source_primary_link();

-- Backfill all sources created after the multi-vehicle link table was introduced.
insert into public.external_review_source_vehicle_links(source_id,generation_id,relation_role)
select e.id,e.generation_id,'subject'
from public.external_review_sources e
on conflict(source_id,generation_id) do update
set relation_role=case
  when public.external_review_source_vehicle_links.relation_role='subject' then 'subject'
  else excluded.relation_role
end;

commit;
