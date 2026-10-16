begin;

create table if not exists public.external_review_source_vehicle_links (
  source_id uuid not null references public.external_review_sources(id) on delete cascade,
  generation_id uuid not null references public.generations(id) on delete cascade,
  relation_role text not null default 'subject'
    check (relation_role in ('subject','comparison','mentioned')),
  created_at timestamptz not null default now(),
  primary key(source_id,generation_id)
);

create index if not exists external_review_vehicle_generation_idx
  on public.external_review_source_vehicle_links(generation_id,source_id);

alter table public.external_review_source_vehicle_links enable row level security;
revoke all on public.external_review_source_vehicle_links from anon,authenticated;
grant select on public.external_review_source_vehicle_links to anon,authenticated;

drop policy if exists "external review vehicle links public read"
  on public.external_review_source_vehicle_links;
create policy "external review vehicle links public read"
on public.external_review_source_vehicle_links
for select to anon,authenticated
using (
  exists (
    select 1 from public.external_review_sources e
    where e.id=source_id and e.approval_status='approved_reference'
  )
  or exists (
    select 1 from public.profiles p
    where p.user_id=(select auth.uid()) and p.role='admin'
  )
);

-- Every existing source gets its primary vehicle link.
insert into public.external_review_source_vehicle_links(source_id,generation_id,relation_role)
select id,generation_id,'subject'
from public.external_review_sources
on conflict(source_id,generation_id) do update
set relation_role=case
  when public.external_review_source_vehicle_links.relation_role='subject' then 'subject'
  else excluded.relation_role
end;

-- Multi-vehicle comparison/editorial sources: link the same canonical source to each relevant generation.
with links(url,brand,model,generation_code,role) as (
values
('https://www.motorgraph.com/news/articleView.html?idxno=41440','토요타','캠리','XV80','comparison'),
('https://www.motorgraph.com/news/articleView.html?idxno=41440','현대','그랜저','GN7','subject'),

('https://www.autoview.co.kr/ko-kr/articles/61408','기아','모닝','JA','subject'),
('https://www.autoview.co.kr/ko-kr/articles/61408','쉐보레','스파크','M400','comparison'),

('https://www.autoview.co.kr/ko-kr/articles/71797','르노코리아','XM3/아르카나','LJL','subject'),
('https://www.autoview.co.kr/ko-kr/articles/71797','기아','셀토스','SP2','comparison'),

('https://www.motorgraph.com/news/articleView.html?idxno=33199','현대','싼타페','MX5','subject'),
('https://www.motorgraph.com/news/articleView.html?idxno=33199','기아','쏘렌토','MQ4','comparison'),

('https://www.autoview.co.kr/ko-kr/boards/2/79134','제네시스','G70','IK','subject'),
('https://www.autoview.co.kr/ko-kr/boards/2/79134','제네시스','G80','RG3','mentioned'),
('https://www.autoview.co.kr/ko-kr/boards/2/79134','기아','K9','RJ','mentioned'),

('https://www.autoview.co.kr/ko-kr/boards/2/71329','현대','싼타페','MX5','subject'),
('https://www.autoview.co.kr/ko-kr/boards/2/71329','기아','쏘렌토','MQ4','comparison'),
('https://www.autoview.co.kr/ko-kr/boards/2/71329','현대','투싼','NX4','comparison')
)
insert into public.external_review_source_vehicle_links(source_id,generation_id,relation_role)
select e.id,g.id,l.role
from links l
join public.external_review_sources e on e.canonical_url=l.url
join public.manufacturers mf on mf.name=l.brand
join public.car_models cm on cm.manufacturer_id=mf.id and cm.name=l.model
join public.generations g on g.car_model_id=cm.id and g.generation_code=l.generation_code
on conflict(source_id,generation_id) do update
set relation_role=excluded.relation_role;

create or replace view public.web_external_review_vehicle_feed
with (security_invoker=true) as
select
  e.id,
  l.generation_id,
  mf.name as brand,
  cm.name as model,
  g.name as generation,
  g.generation_code,
  l.relation_role,
  e.source_type,
  e.source_name,
  e.title,
  e.canonical_url as source_url,
  e.published_date,
  e.observed_date,
  e.author_label,
  e.powertrain_hint,
  e.trim_hint,
  e.summary,
  e.source_confidence,
  e.dedupe_status
from public.external_review_source_vehicle_links l
join public.external_review_sources e on e.id=l.source_id
join public.generations g on g.id=l.generation_id
join public.car_models cm on cm.id=g.car_model_id
join public.manufacturers mf on mf.id=cm.manufacturer_id
where e.approval_status='approved_reference';

grant select on public.web_external_review_vehicle_feed to anon,authenticated;

commit;
