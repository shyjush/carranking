-- CarRanking official vehicle specifications: EV batch
-- Sources: Kia Korea official specification pages, checked 2026-08-31.
-- Uses actual schema: generations.car_model_id / generations.current.

begin;

with spec_data(model_name, length_mm, width_mm, height_mm, wheelbase_mm, combined_efficiency, source_url, note) as (
  values
    ('EV6', 4695, 1880, 1550, 2900, '5.5 km/kWh (Standard 2WD 19-inch)',
     'https://www.kia.com/kr/vehicles/ev6/specification',
     'Kia official specification: EV6 base body 4,695 x 1,880 x 1,550 mm, wheelbase 2,900 mm. GT-Line width is 1,890 mm. Standard 2WD 19-inch combined efficiency 5.5 km/kWh.'),
    ('EV9', 5010, 1980, 1755, 3100, '4.2 km/kWh (Standard 2WD 19-inch)',
     'https://www.kia.com/kr/vehicles/ev9/specification',
     'Kia official specification: EV9 base body 5,010 x 1,980 x 1,755 mm, wheelbase 3,100 mm. GT-Line dimensions vary. Standard 2WD 19-inch combined efficiency 4.2 km/kWh.')
)
insert into public.vehicle_specs
  (generation_id, length_mm, width_mm, height_mm, wheelbase_mm, combined_efficiency, source_url, verified_at)
select g.id, s.length_mm, s.width_mm, s.height_mm, s.wheelbase_mm, s.combined_efficiency, s.source_url, date '2026-08-31'
from spec_data s
join public.manufacturers mf on mf.name = '기아'
join public.car_models cm on cm.manufacturer_id = mf.id and cm.name = s.model_name
join public.generations g on g.car_model_id = cm.id and g.current = true
where not exists (
  select 1 from public.vehicle_specs vs
  where vs.generation_id = g.id and vs.powertrain_id is null
);

with source_data(model_name, source_url, note) as (
  values
    ('EV6', 'https://www.kia.com/kr/vehicles/ev6/specification',
     'Kia official specification: EV6 body, battery/output variants, efficiency and driving range by drivetrain/wheel.'),
    ('EV9', 'https://www.kia.com/kr/vehicles/ev9/specification',
     'Kia official specification: EV9 base/GT-Line body dimensions, battery/output variants, efficiency and driving range by drivetrain/wheel.')
)
insert into public.source_records (entity_type, entity_id, source_url, confidence, verified_at, note)
select 'generation', g.id, s.source_url, 'A', date '2026-08-31', s.note
from source_data s
join public.manufacturers mf on mf.name = '기아'
join public.car_models cm on cm.manufacturer_id = mf.id and cm.name = s.model_name
join public.generations g on g.car_model_id = cm.id and g.current = true
where not exists (
  select 1 from public.source_records sr
  where sr.entity_type='generation' and sr.entity_id=g.id and sr.source_url=s.source_url
);

commit;
