begin;

-- Hyundai The new IONIQ 5: official Hyundai catalog verified 2026-08-31.
-- Keep wheel/drivetrain-specific efficiency on powertrain-linked vehicle_specs.

with target as (
  select g.id as generation_id
  from public.generations g
  join public.car_models cm on cm.id = g.car_model_id
  join public.manufacturers mf on mf.id = cm.manufacturer_id
  where mf.name = '현대' and cm.name = '아이오닉 5' and g.current = true
  order by g.start_year desc nulls last
  limit 1
), vals(name, battery_kwh, max_power_ps) as (
  values
    ('Standard 2WD', 63.0::numeric, 170::numeric),
    ('Long Range 2WD', 84.0::numeric, 229::numeric),
    ('Long Range AWD', 84.0::numeric, 325::numeric)
)
insert into public.powertrains (generation_id, name, fuel_type, battery_kwh, max_power_ps)
select t.generation_id, v.name, '전기', v.battery_kwh, v.max_power_ps
from target t cross join vals v
where not exists (
  select 1 from public.powertrains p
  where p.generation_id = t.generation_id and p.name = v.name
);

-- Base body dimensions are common to Standard/Long Range current IONIQ 5.
with target as (
  select g.id as generation_id
  from public.generations g
  join public.car_models cm on cm.id = g.car_model_id
  join public.manufacturers mf on mf.id = cm.manufacturer_id
  where mf.name = '현대' and cm.name = '아이오닉 5' and g.current = true
  order by g.start_year desc nulls last
  limit 1
)
insert into public.vehicle_specs
  (generation_id, length_mm, width_mm, height_mm, wheelbase_mm, source_url, verified_at)
select generation_id, 4655, 1890, 1605, 3000,
       'https://www.hyundai.com/content/dam/hyundai/kr/ko/data/vehicles/catalog/en/the-new-ioniq5-catalog-eng.pdf',
       date '2026-08-31'
from target t
where not exists (
  select 1 from public.vehicle_specs s
  where s.generation_id = t.generation_id and s.powertrain_id is null
);

-- Government-reported combined efficiency / range from Hyundai official catalog.
with target as (
  select g.id as generation_id
  from public.generations g
  join public.car_models cm on cm.id = g.car_model_id
  join public.manufacturers mf on mf.id = cm.manufacturer_id
  where mf.name = '현대' and cm.name = '아이오닉 5' and g.current = true
  order by g.start_year desc nulls last
  limit 1
), vals(name, efficiency) as (
  values
    ('Standard 2WD', '5.1 km/kWh (19-inch; combined range 368 km)'),
    ('Long Range 2WD', '5.2 km/kWh (19-inch without built-in cam; combined range 485 km)'),
    ('Long Range AWD', '4.8 km/kWh (19-inch; combined range 451 km)')
)
insert into public.vehicle_specs
  (generation_id, powertrain_id, length_mm, width_mm, height_mm, wheelbase_mm,
   combined_efficiency, source_url, verified_at)
select t.generation_id, p.id, 4655, 1890, 1605, 3000, v.efficiency,
       'https://www.hyundai.com/content/dam/hyundai/kr/ko/data/vehicles/catalog/en/the-new-ioniq5-catalog-eng.pdf',
       date '2026-08-31'
from target t
join vals v on true
join public.powertrains p on p.generation_id = t.generation_id and p.name = v.name
where not exists (
  select 1 from public.vehicle_specs s where s.powertrain_id = p.id
);

commit;
