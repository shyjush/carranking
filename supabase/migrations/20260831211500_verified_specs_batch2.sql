begin;

-- Verified current-generation body dimensions from official manufacturer pages.
-- Generation-level dimensions only; powertrain-specific efficiency remains separate.
with verified(brand, model, length_mm, width_mm, height_mm, wheelbase_mm, source_url) as (
  values
    ('기아','K8',5050,1880,1455,2895,'https://www.kia.com/kr/vehicles/k8/specification'),
    ('제네시스','G70',4685,1850,1400,2835,'https://www.genesis.com/kr/ko/models/g70'),
    ('제네시스','GV70',4715,1910,1630,2875,'https://www.genesis.com/kr/ko/models/gv70')
), targets as (
  select g.id as generation_id, v.*
  from verified v
  join public.manufacturers mf on mf.name=v.brand
  join public.car_models cm on cm.manufacturer_id=mf.id and cm.name=v.model
  join public.generations g on g.car_model_id=cm.id and g.current=true
)
insert into public.vehicle_specs
  (generation_id,length_mm,width_mm,height_mm,wheelbase_mm,source_url,verified_at)
select generation_id,length_mm,width_mm,height_mm,wheelbase_mm,source_url,current_date
from targets t
where not exists (
  select 1 from public.vehicle_specs s
  where s.generation_id=t.generation_id and s.powertrain_id is null
);

commit;
