begin;

-- Batch 4: official manufacturer specifications verified 2026-08-31.
-- Only current generations are targeted. Values with wheel/roof-rack variants use the
-- manufacturer's base body figure; variant-specific values belong in later powertrain/trim rows.

with specs(brand, model, length_mm, width_mm, height_mm, wheelbase_mm, source_url) as (
  values
    ('Kia','Sportage',4685,1865,1660,2755,'https://www.kia.com/kr/vehicles/sportage/specification'),
    ('Kia','Seltos',4430,1830,1600,2690,'https://www.kia.com/kr/vehicles/seltos/specification')
), targets as (
  select g.id as generation_id, s.*
  from specs s
  join public.manufacturers mf on mf.name=s.brand
  join public.car_models cm on cm.manufacturer_id=mf.id and cm.name=s.model
  join public.generations g on g.car_model_id=cm.id and g.current=true
)
insert into public.vehicle_specs
  (generation_id, length_mm, width_mm, height_mm, wheelbase_mm, source_url, verified_at)
select generation_id, length_mm, width_mm, height_mm, wheelbase_mm, source_url, date '2026-08-31'
from targets t
where not exists (
  select 1 from public.vehicle_specs v
  where v.generation_id=t.generation_id and v.powertrain_id is null
);

insert into public.source_records(entity_type, entity_id, source_url, confidence, verified_at, note)
select 'generation', g.id, s.source_url, 'A', date '2026-08-31', 'Official manufacturer specification page; body dimensions.'
from (values
  ('Kia','Sportage','https://www.kia.com/kr/vehicles/sportage/specification'),
  ('Kia','Seltos','https://www.kia.com/kr/vehicles/seltos/specification')
) s(brand,model,source_url)
join public.manufacturers mf on mf.name=s.brand
join public.car_models cm on cm.manufacturer_id=mf.id and cm.name=s.model
join public.generations g on g.car_model_id=cm.id and g.current=true
where not exists (
  select 1 from public.source_records sr
  where sr.entity_type='generation' and sr.entity_id=g.id and sr.source_url=s.source_url
);

commit;
