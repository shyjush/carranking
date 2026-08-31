begin;

create table if not exists public.editorial_reference_reviews (
  id uuid primary key default gen_random_uuid(),
  generation_id uuid not null references public.generations(id) on delete cascade,
  slot int not null check (slot between 1 and 5),
  title text not null,
  body text not null,
  source_label text not null default 'CarRanking 초기 참고리뷰',
  is_reference boolean not null default true,
  created_at timestamptz not null default now(),
  unique(generation_id, slot)
);
alter table public.editorial_reference_reviews enable row level security;
grant select on public.editorial_reference_reviews to anon, authenticated;
drop policy if exists "editorial reference reviews public read" on public.editorial_reference_reviews;
create policy "editorial reference reviews public read" on public.editorial_reference_reviews for select to anon, authenticated using (true);

with top5 as (
  select dm.generation_id, dm.retention_rate
  from public.depreciation_metrics dm
  where dm.retention_rate is not null
  order by dm.retention_rate desc nulls last
  limit 5
), templates(slot,title,body) as (
  values
    (1,'가치보존 관점에서 눈여겨볼 차','중고시장 가치보존 지표가 상대적으로 좋은 편으로 집계된 차량입니다. 실제 구매에서는 주행거리와 사고이력, 옵션, 관리상태에 따라 체감 가치가 크게 달라질 수 있습니다.'),
    (2,'실사용 균형을 함께 확인하세요','차량 선택에서는 감가방어뿐 아니라 승차감, 정숙성, 공간 활용성, 연료비와 정비비를 함께 보는 것이 좋습니다. 이 글은 초기 비교를 돕기 위한 CarRanking 편집 참고리뷰입니다.'),
    (3,'중고차 구매라면 상태가 더 중요','같은 연식과 모델이라도 소모품 교환 이력과 사고·수리 이력, 타이어 상태, 보증 잔여기간에 따라 만족도가 달라집니다. 시세만 보지 말고 개별 차량 상태를 반드시 확인할 필요가 있습니다.'),
    (4,'보유기간까지 고려한 선택','짧게 보유할 계획이라면 감가방어가 중요한 판단요소가 될 수 있고, 장기보유라면 유지비와 신뢰성의 비중이 더 커집니다. 자신의 예상 보유기간을 먼저 정하고 비교하는 것을 권합니다.')
)
insert into public.editorial_reference_reviews(generation_id,slot,title,body)
select t.generation_id,x.slot,x.title,x.body from top5 t cross join templates x
on conflict(generation_id,slot) do update set title=excluded.title,body=excluded.body,source_label='CarRanking 초기 참고리뷰',is_reference=true;

create or replace view public.web_review_feed with (security_invoker=true) as
select r.id,r.generation_id,r.title,r.body,r.created_at,coalesce(p.display_name,'익명 오너') display_name,
       mf.name brand,cm.name model,g.name generation,g.generation_code,false as is_reference,'오너리뷰'::text as review_type
from public.reviews r
join public.generations g on g.id=r.generation_id
join public.car_models cm on cm.id=g.car_model_id
join public.manufacturers mf on mf.id=cm.manufacturer_id
left join public.profiles p on p.user_id=r.user_id
where r.status='published'
union all
select e.id,e.generation_id,e.title,e.body,e.created_at,e.source_label,
       mf.name,cm.name,g.name,g.generation_code,true,'초기 참고리뷰'::text
from public.editorial_reference_reviews e
join public.generations g on g.id=e.generation_id
join public.car_models cm on cm.id=g.car_model_id
join public.manufacturers mf on mf.id=cm.manufacturer_id;
grant select on public.web_review_feed to anon, authenticated;
commit;