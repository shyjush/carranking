begin;

-- Batch 6: manufacturer-verified current vehicle dimensions.
-- Match actual Korean seed names. Idempotent inserts only.

with target as (
  select g.id as generation_id
  from public.generations g
  join public.car_models m on m.id = g.car_model_id
  join public.manufacturers mf on mf.id = m.manufacturer_id
  where mf.name = '현대' and m.name = '팰리세이드' and g.current = true
  order by g.start_year desc nulls last
  limit 1
)
insert into public.vehicle_specs
  (generation_id, length_mm, width_mm, height_mm, wheelbase_mm, source_url, verified_at)
select generation_id, 5060, 1980, 1805, 2970,
       'https://www.hyundai.com/kr/ko/brand/brandstory/heritage/2025-palisade', date '2026-08-31'
from target
where not exists (
  select 1 from public.vehicle_specs vs
  where vs.generation_id = target.generation_id and vs.powertrain_id is null
);

with target as (
  select g.id as generation_id
  from public.generations g
  join public.car_models m on m.id = g.car_model_id
  join public.manufacturers mf on mf.id = m.manufacturer_id
  where mf.name = '기아' and m.name = 'EV3' and g.current = true
  order by g.start_year desc nulls last
  limit 1
)
insert into public.vehicle_specs
  (generation_id, length_mm, width_mm, height_mm, wheelbase_mm, combined_efficiency, source_url, verified_at)
select generation_id, 4300, 1850, 1560, 2680,
       '5.2 km/kWh (Standard 2WD 17-inch)',
       'https://www.kia.com/kr/vehicles/ev3/specification', date '2026-08-31'
from target
where not exists (
  select 1 from public.vehicle_specs vs
  where vs.generation_id = target.generation_id and vs.powertrain_id is null
);

insert into public.source_records (entity_type, entity_id, source_url, confidence, verified_at, note)
select 'generation', g.id,
       'https://www.hyundai.com/kr/ko/brand/brandstory/heritage/2025-palisade',
       'A-', date '2026-08-31',
       'Hyundai official heritage page for 2025 all-new Palisade: 5,060 x 1,980 x 1,805 mm; wheelbase 2,970 mm.'
from public.generations g
join public.car_models m on m.id=g.car_model_id
join public.manufacturers mf on mf.id=m.manufacturer_id
where mf.name='현대' and m.name='팰리세이드' and g.current=true
  and not exists (
    select 1 from public.source_records sr
    where sr.entity_type='generation' and sr.entity_id=g.id
      and sr.source_url='https://www.hyundai.com/kr/ko/brand/brandstory/heritage/2025-palisade'
  );

insert into public.source_records (entity_type, entity_id, source_url, confidence, verified_at, note)
select 'generation', g.id,
       'https://www.kia.com/kr/vehicles/ev3/specification',
       'A', date '2026-08-31',
       'Kia official EV3 specification. Base 4,300 x 1,850 x 1,560 mm; wheelbase 2,680 mm. GT-Line/4WD/roof-rack variants differ; Standard 2WD 17-inch combined efficiency 5.2 km/kWh.'
from public.generations g
join public.car_models m on m.id=g.car_model_id
join public.manufacturers mf on mf.id=m.manufacturer_id
where mf.name='기아' and m.name='EV3' and g.current=true
  and not exists (
    select 1 from public.source_records sr
    where sr.entity_type='generation' and sr.entity_id=g.id
      and sr.source_url='https://www.kia.com/kr/vehicles/ev3/specification'
  );

commit;
