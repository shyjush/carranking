begin;

-- Correct the i5 eDrive40 efficiency field to the official Korean combined
-- electric-efficiency value. The launch-range figure remains preserved in its
-- source record note and is not stored in the efficiency column.

update public.vehicle_specs vs
set combined_efficiency = '4.8 km/kWh (복합)',
    verified_at = date '2026-10-20'
from public.powertrains p
join public.generations g on g.id = p.generation_id
join public.car_models cm on cm.id = g.car_model_id
join public.manufacturers mf on mf.id = cm.manufacturer_id
where vs.powertrain_id = p.id
  and mf.name = 'BMW'
  and cm.name = 'i5'
  and g.generation_code = 'G60'
  and g.start_year = 2024
  and p.name = 'i5 eDrive40'
  and vs.combined_efficiency = '385 km (1회 충전, 21인치 인증)';

insert into public.source_records
  (entity_type, entity_id, source_url, confidence, verified_at, note)
select 'powertrain', p.id,
       'https://www.bmw.co.kr/ko/all-models/i-series/i5/i5-2023-g60bev.html',
       'A', date '2026-10-20',
       'BMW 코리아 공식 i5 모델정보. i5 eDrive40 복합전비 4.8km/kWh.'
from public.powertrains p
join public.generations g on g.id = p.generation_id
join public.car_models cm on cm.id = g.car_model_id
join public.manufacturers mf on mf.id = cm.manufacturer_id
where mf.name = 'BMW'
  and cm.name = 'i5'
  and g.generation_code = 'G60'
  and g.start_year = 2024
  and p.name = 'i5 eDrive40'
  and not exists (
    select 1 from public.source_records sr
    where sr.entity_type = 'powertrain'
      and sr.entity_id = p.id
      and sr.source_url = 'https://www.bmw.co.kr/ko/all-models/i-series/i5/i5-2023-g60bev.html'
  );

commit;
