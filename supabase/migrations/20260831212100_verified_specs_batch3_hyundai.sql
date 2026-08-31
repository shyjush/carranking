begin;

-- Hyundai official specifications batch.
-- Insert only when a matching current generation exists and no generation-level spec exists.
with spec_data(manufacturer_name, model_name, length_mm, width_mm, height_mm, wheelbase_mm, source_url, verified_at) as (
  values
    ('현대', '그랜저', 5035, 1880, 1460, 2895, 'https://www.hyundai.com/kr/ko/brand/brandstory/heritage/2022-the-all-new-grandeur', date '2026-08-31'),
    ('현대', '쏘나타', 4910, 1860, 1445, 2840, 'https://org1.hyundai.com/kr/ko/e/customer/guide/disabled-purchase-guide', date '2026-08-31'),
    ('현대', '아반떼', 4710, 1825, 1420, 2720, 'https://www.hyundai.com/kr/ko/e/vehicles/avante/intro', date '2026-08-31'),
    ('현대', '싼타페', 4830, 1900, 1730, 2815, 'https://www.hyundai.com/kr/ko/brand/brandstory/heritage/2023-the-all-new-santafe', date '2026-08-31')
)
insert into public.vehicle_specs (
  generation_id, length_mm, width_mm, height_mm, wheelbase_mm,
  source_url, verified_at
)
select g.id, s.length_mm, s.width_mm, s.height_mm, s.wheelbase_mm,
       s.source_url, s.verified_at
from spec_data s
join public.manufacturers mf on mf.name = s.manufacturer_name
join public.car_models cm on cm.manufacturer_id = mf.id and cm.name = s.model_name
join public.generations g on g.car_model_id = cm.id and g.current = true
where not exists (
  select 1 from public.vehicle_specs vs
  where vs.generation_id = g.id and vs.powertrain_id is null
);

commit;
