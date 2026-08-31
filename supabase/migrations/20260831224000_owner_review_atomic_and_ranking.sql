begin;

-- Atomic public owner-review submission plus owner-score ranking.
-- Keeps the browser on the publishable key while all write validation happens in Postgres.
create or replace function public.submit_owner_review(
  p_generation_id uuid,
  p_visitor_id text,
  p_ride_comfort int,
  p_quietness int,
  p_performance int,
  p_fuel_efficiency int,
  p_maintenance_cost int,
  p_reliability int,
  p_design int,
  p_convenience int,
  p_resale_value int,
  p_repurchase_intent int,
  p_title text,
  p_body text
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_generation_id is null then raise exception 'generation required'; end if;
  if p_visitor_id is null or length(p_visitor_id) not between 16 and 100 then raise exception 'invalid visitor'; end if;
  if p_body is null or length(trim(p_body)) not between 10 and 2000 then raise exception 'invalid body'; end if;
  if p_title is not null and length(p_title) > 100 then raise exception 'invalid title'; end if;
  if p_ride_comfort not between 1 and 10 or p_quietness not between 1 and 10 or
     p_performance not between 1 and 10 or p_fuel_efficiency not between 1 and 10 or
     p_maintenance_cost not between 1 and 10 or p_reliability not between 1 and 10 or
     p_design not between 1 and 10 or p_convenience not between 1 and 10 or
     p_resale_value not between 1 and 10 or p_repurchase_intent not between 1 and 10 then
    raise exception 'ratings must be 1..10';
  end if;
  if not exists(select 1 from public.generations where id=p_generation_id) then raise exception 'unknown generation'; end if;

  insert into public.ratings(
    user_id,visitor_id,generation_id,ride_comfort,quietness,performance,fuel_efficiency,
    maintenance_cost,reliability,design,convenience,resale_value,repurchase_intent
  ) values (
    null,p_visitor_id,p_generation_id,p_ride_comfort,p_quietness,p_performance,p_fuel_efficiency,
    p_maintenance_cost,p_reliability,p_design,p_convenience,p_resale_value,p_repurchase_intent
  );

  insert into public.reviews(user_id,visitor_id,generation_id,title,body,status)
  values(null,p_visitor_id,p_generation_id,nullif(trim(p_title),''),trim(p_body),'published');

  return jsonb_build_object('ok',true);
exception
  when unique_violation then
    raise exception 'already reviewed';
end;
$$;

revoke all on function public.submit_owner_review(uuid,text,int,int,int,int,int,int,int,int,int,int,text,text) from public;
grant execute on function public.submit_owner_review(uuid,text,int,int,int,int,int,int,int,int,int,int,text,text) to anon, authenticated;

create or replace view public.web_owner_ranking
with (security_invoker = true) as
select
  rs.generation_id,
  mf.name as brand,
  cm.name as model,
  g.name as generation,
  g.generation_code,
  cm.category,
  rs.rating_count,
  rs.overall_score,
  rs.ride_comfort, rs.quietness, rs.performance, rs.fuel_efficiency,
  rs.maintenance_cost, rs.reliability, rs.design, rs.convenience,
  rs.resale_value, rs.repurchase_intent
from public.web_rating_summary rs
join public.generations g on g.id=rs.generation_id
join public.car_models cm on cm.id=g.car_model_id
join public.manufacturers mf on mf.id=cm.manufacturer_id;

grant select on public.web_owner_ranking to anon, authenticated;

create or replace view public.web_review_feed
with (security_invoker = true) as
select r.id, r.generation_id, r.title, r.body, r.created_at,
       coalesce(p.display_name,'익명 오너') display_name,
       mf.name brand, cm.name model, g.name generation, g.generation_code
from public.reviews r
join public.generations g on g.id=r.generation_id
join public.car_models cm on cm.id=g.car_model_id
join public.manufacturers mf on mf.id=cm.manufacturer_id
left join public.profiles p on p.user_id=r.user_id
where r.status='published';

grant select on public.web_review_feed to anon, authenticated;

commit;
