begin;

-- The new IONIQ 6 official Hyundai EV powertrain data.
-- Source: Hyundai official battery information / current IONIQ 6 price page.
-- Body dimensions intentionally omitted until a current official specification source is verified.

with target_generation as (
  select g.id as generation_id
  from public.generations g
  join public.car_models cm on cm.id = g.car_model_id
  join public.manufacturers mf on mf.id = cm.manufacturer_id
  where mf.name = '현대'
    and cm.name in ('아이오닉 6', '아이오닉6')
    and g.current = true
  order by g.start_year desc nulls last
  limit 1
), powertrain_data(name, fuel_type, max_power_ps, battery_kwh) as (
  values
    ('스탠다드 2WD', '전기', 170::numeric, 63.0::numeric),
    ('롱레인지 2WD', '전기', 229::numeric, 84.0::numeric),
    ('롱레인지 AWD', '전기', 325::numeric, 84.0::numeric)
)
insert into public.powertrains (generation_id, name, fuel_type, max_power_ps, battery_kwh)
select tg.generation_id, p.name, p.fuel_type, p.max_power_ps, p.battery_kwh
from target_generation tg
cross join powertrain_data p
where not exists (
  select 1
  from public.powertrains existing
  where existing.generation_id = tg.generation_id
    and existing.name = p.name
);

-- Provenance: one A-grade official Hyundai source per inserted/matched powertrain.
insert into public.source_records (entity_type, entity_id, source_url, confidence, verified_at, note)
select
  'powertrain',
  p.id,
  'https://www.hyundai.com/kr/ko/service-membership/ev/ev-battery-cell-information',
  'A',
  date '2026-08-31',
  'Hyundai official EV battery information: The new IONIQ 6 battery capacity and motor output.'
from public.powertrains p
join public.generations g on g.id = p.generation_id
join public.car_models cm on cm.id = g.car_model_id
join public.manufacturers mf on mf.id = cm.manufacturer_id
where mf.name = '현대'
  and cm.name in ('아이오닉 6', '아이오닉6')
  and g.current = true
  and p.name in ('스탠다드 2WD', '롱레인지 2WD', '롱레인지 AWD')
  and not exists (
    select 1 from public.source_records sr
    where sr.entity_type = 'powertrain'
      and sr.entity_id = p.id
      and sr.source_url = 'https://www.hyundai.com/kr/ko/service-membership/ev/ev-battery-cell-information'
  );

commit;
