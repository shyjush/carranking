begin;

-- Batch 1: manufacturer-official current specs, verified 2026-08-31.
-- Generation matching is deliberately constrained by brand/model/current to avoid attaching specs to historical generations.

-- Genesis G80 (official Genesis Korea)
insert into public.vehicle_specs (generation_id,length_mm,width_mm,height_mm,wheelbase_mm,source_url,verified_at)
select g.id,5005,1925,1465,3010,'https://www.genesis.com/kr/ko/models/g80','2026-08-31'
from public.generations g
join public.car_models cm on cm.id=g.car_model_id
join public.manufacturers mf on mf.id=cm.manufacturer_id
where mf.name in ('제네시스','Genesis') and cm.name='G80' and g.current=true
and not exists (select 1 from public.vehicle_specs s where s.generation_id=g.id and s.powertrain_id is null);

-- Genesis GV80 (official Genesis Korea)
insert into public.vehicle_specs (generation_id,length_mm,width_mm,height_mm,wheelbase_mm,source_url,verified_at)
select g.id,4940,1975,1715,2955,'https://www.genesis.com/kr/ko/models/gv80','2026-08-31'
from public.generations g
join public.car_models cm on cm.id=g.car_model_id
join public.manufacturers mf on mf.id=cm.manufacturer_id
where mf.name in ('제네시스','Genesis') and cm.name='GV80' and g.current=true
and not exists (select 1 from public.vehicle_specs s where s.generation_id=g.id and s.powertrain_id is null);

-- Kia Sorento current generation (official Kia Korea). Height 1695 excludes roof-rack option.
insert into public.vehicle_specs (generation_id,length_mm,width_mm,height_mm,wheelbase_mm,source_url,verified_at)
select g.id,4815,1900,1695,2815,'https://www.kia.com/kr/vehicles/sorento/specification','2026-08-31'
from public.generations g
join public.car_models cm on cm.id=g.car_model_id
join public.manufacturers mf on mf.id=cm.manufacturer_id
where mf.name in ('기아','Kia') and cm.name='쏘렌토' and g.current=true
and not exists (select 1 from public.vehicle_specs s where s.generation_id=g.id and s.powertrain_id is null);

commit;
