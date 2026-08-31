begin;

create or replace view public.web_home_featured
with (security_invoker = true) as
select mf.name brand, cm.name model, cm.slug model_slug, g.name generation,
       g.generation_code, cm.category, g.start_year, g.current
from public.generations g
join public.car_models cm on cm.id=g.car_model_id
join public.manufacturers mf on mf.id=cm.manufacturer_id
where g.current = true;

create or replace view public.web_value_ranking
with (security_invoker = true) as
select row_number() over(order by dm.retention_rate desc nulls last) rank,
       mf.name brand, cm.name model, g.name generation, g.generation_code,
       cm.category, dm.model_year, dm.original_price_krw, dm.used_price_krw,
       dm.retention_rate, dm.depreciation_rate, dm.sample_size, dm.as_of_date,
       dm.confidence, dm.note
from public.depreciation_metrics dm
join public.generations g on g.id=dm.generation_id
join public.car_models cm on cm.id=g.car_model_id
join public.manufacturers mf on mf.id=cm.manufacturer_id
where dm.retention_rate is not null;

create or replace view public.web_vehicle_detail
with (security_invoker = true) as
select mf.name brand, cm.name model, cm.slug model_slug, cm.category,
       g.id generation_id, g.name generation, g.generation_code,
       g.start_year, g.end_year, g.current,
       dm.model_year, dm.original_price_krw, dm.used_price_krw,
       dm.retention_rate, dm.depreciation_rate, dm.sample_size,
       dm.as_of_date, dm.confidence
from public.generations g
join public.car_models cm on cm.id=g.car_model_id
join public.manufacturers mf on mf.id=cm.manufacturer_id
left join lateral (
  select d.* from public.depreciation_metrics d
  where d.generation_id=g.id
  order by d.as_of_date desc nulls last limit 1
) dm on true;

create or replace view public.web_compare_base
with (security_invoker = true) as
select mf.name brand, cm.name model, g.id generation_id, g.name generation,
       g.generation_code, cm.category,
       vs.length_mm, vs.width_mm, vs.height_mm, vs.wheelbase_mm,
       vs.combined_efficiency,
       dm.retention_rate, dm.depreciation_rate, dm.as_of_date, dm.confidence
from public.generations g
join public.car_models cm on cm.id=g.car_model_id
join public.manufacturers mf on mf.id=cm.manufacturer_id
left join lateral (
  select s.* from public.vehicle_specs s where s.generation_id=g.id
  order by s.verified_at desc nulls last limit 1
) vs on true
left join lateral (
  select d.* from public.depreciation_metrics d where d.generation_id=g.id
  order by d.as_of_date desc nulls last limit 1
) dm on true;

create or replace view public.web_rating_summary
with (security_invoker = true) as
select generation_id, count(*) rating_count,
 avg(ride_comfort)::numeric(4,2) ride_comfort,
 avg(quietness)::numeric(4,2) quietness,
 avg(performance)::numeric(4,2) performance,
 avg(fuel_efficiency)::numeric(4,2) fuel_efficiency,
 avg(maintenance_cost)::numeric(4,2) maintenance_cost,
 avg(reliability)::numeric(4,2) reliability,
 avg(design)::numeric(4,2) design,
 avg(convenience)::numeric(4,2) convenience,
 avg(resale_value)::numeric(4,2) resale_value,
 avg(repurchase_intent)::numeric(4,2) repurchase_intent,
 (
  avg(ride_comfort)*0.12 + avg(quietness)*0.10 + avg(performance)*0.10 +
  avg(fuel_efficiency)*0.10 + avg(maintenance_cost)*0.10 + avg(reliability)*0.14 +
  avg(design)*0.08 + avg(convenience)*0.08 + avg(resale_value)*0.10 +
  avg(repurchase_intent)*0.08
 )::numeric(4,2) overall_score
from public.ratings group by generation_id;

create or replace view public.web_review_feed
with (security_invoker = true) as
select r.id, r.generation_id, r.title, r.body, r.created_at,
       p.display_name
from public.reviews r
left join public.profiles p on p.user_id=r.user_id
where r.status='published';

create or replace view public.web_search_index
with (security_invoker = true) as
select g.id generation_id, mf.name brand, cm.name model, cm.slug model_slug,
       g.name generation, g.generation_code, cm.category, g.current,
       concat_ws(' ',mf.name,cm.name,g.name,g.generation_code) search_text
from public.generations g
join public.car_models cm on cm.id=g.car_model_id
join public.manufacturers mf on mf.id=cm.manufacturer_id;

grant select on public.web_home_featured, public.web_value_ranking,
 public.web_vehicle_detail, public.web_compare_base, public.web_rating_summary,
 public.web_review_feed, public.web_search_index to anon, authenticated;

commit;
