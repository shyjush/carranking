begin;

-- Hyundai IONIQ 9 official specifications / powertrains.
-- Source: Hyundai Korea official catalog/heritage, verified 2026-08-31.
-- Dimensions are common across the catalog variants listed below.

-- Generation-level dimensions.
insert into public.vehicle_specs (generation_id,length_mm,width_mm,height_mm,wheelbase_mm,source_url,verified_at)
select g.id,5060,1980,1790,3130,'https://www.hyundai.com/kr/ko/brand/brandstory/heritage/2025-ioniq9','2026-08-31'
from public.generations g
join public.car_models cm on cm.id=g.car_model_id
join public.manufacturers mf on mf.id=cm.manufacturer_id
where mf.name in ('현대','Hyundai','현대자동차')
  and cm.name in ('아이오닉 9','IONIQ 9','아이오닉9')
  and g.current=true
  and not exists (
    select 1 from public.vehicle_specs s where s.generation_id=g.id and s.powertrain_id is null
  );

-- Powertrains: all use the official 110.3 kWh battery.
insert into public.powertrains (generation_id,name,fuel_type,max_power_ps,battery_kwh)
select g.id,v.name,'전기',v.ps,110.3
from public.generations g
join public.car_models cm on cm.id=g.car_model_id
join public.manufacturers mf on mf.id=cm.manufacturer_id
cross join (values
 ('항속형 2WD',218::numeric),
 ('항속형 AWD',308::numeric),
 ('성능형 AWD',428::numeric)
) as v(name,ps)
where mf.name in ('현대','Hyundai','현대자동차')
  and cm.name in ('아이오닉 9','IONIQ 9','아이오닉9')
  and g.current=true
  and not exists (
    select 1 from public.powertrains p where p.generation_id=g.id and p.name=v.name
  );

-- Official combined efficiency for 19-inch variants where published in the catalog.
insert into public.vehicle_specs (generation_id,powertrain_id,length_mm,width_mm,height_mm,wheelbase_mm,combined_efficiency,source_url,verified_at)
select p.generation_id,p.id,5060,1980,1790,3130,v.eff,
       'https://www.hyundai.com/contents/repn-car/catalog/ioniq9-catalog.pdf','2026-08-31'
from public.powertrains p
join public.generations g on g.id=p.generation_id
join public.car_models cm on cm.id=g.car_model_id
join public.manufacturers mf on mf.id=cm.manufacturer_id
join (values
 ('항속형 2WD','4.3 km/kWh'),
 ('항속형 AWD','4.1 km/kWh')
) as v(name,eff) on v.name=p.name
where mf.name in ('현대','Hyundai','현대자동차')
  and cm.name in ('아이오닉 9','IONIQ 9','아이오닉9')
  and g.current=true
  and not exists (
    select 1 from public.vehicle_specs s where s.powertrain_id=p.id
  );

-- A-confidence provenance for the current generation.
insert into public.source_records (entity_type,entity_id,source_url,confidence,verified_at,note)
select 'generation',g.id,'https://www.hyundai.com/contents/repn-car/catalog/ioniq9-catalog.pdf','A','2026-08-31',
       'Hyundai official catalog: dimensions, 110.3 kWh battery, output, efficiency and range by drivetrain/wheel.'
from public.generations g
join public.car_models cm on cm.id=g.car_model_id
join public.manufacturers mf on mf.id=cm.manufacturer_id
where mf.name in ('현대','Hyundai','현대자동차')
  and cm.name in ('아이오닉 9','IONIQ 9','아이오닉9')
  and g.current=true
  and not exists (
    select 1 from public.source_records sr
    where sr.entity_type='generation' and sr.entity_id=g.id
      and sr.source_url='https://www.hyundai.com/contents/repn-car/catalog/ioniq9-catalog.pdf'
  );

commit;
