begin;

-- Official Kia EV powertrain data, verified 2026-08-31.
-- Powertrains are separated by battery/drivetrain where official specs differ.

-- EV3
with target as (
  select g.id generation_id from public.generations g
  join public.car_models cm on cm.id=g.car_model_id
  join public.manufacturers mf on mf.id=cm.manufacturer_id
  where mf.name in ('기아','Kia') and cm.name='EV3' and g.current=true limit 1
)
insert into public.powertrains (generation_id,name,fuel_type,max_power_ps,battery_kwh)
select generation_id,'스탠다드 2WD','전기',204,58.3 from target
where not exists (select 1 from public.powertrains p where p.generation_id=target.generation_id and p.name='스탠다드 2WD');

with target as (select g.id generation_id from public.generations g join public.car_models cm on cm.id=g.car_model_id join public.manufacturers mf on mf.id=cm.manufacturer_id where mf.name in ('기아','Kia') and cm.name='EV3' and g.current=true limit 1)
insert into public.powertrains (generation_id,name,fuel_type,max_power_ps,battery_kwh)
select generation_id,'롱레인지 2WD','전기',204,81.4 from target where not exists (select 1 from public.powertrains p where p.generation_id=target.generation_id and p.name='롱레인지 2WD');

with target as (select g.id generation_id from public.generations g join public.car_models cm on cm.id=g.car_model_id join public.manufacturers mf on mf.id=cm.manufacturer_id where mf.name in ('기아','Kia') and cm.name='EV3' and g.current=true limit 1)
insert into public.powertrains (generation_id,name,fuel_type,max_power_ps,battery_kwh)
select generation_id,'롱레인지 4WD','전기',265,81.4 from target where not exists (select 1 from public.powertrains p where p.generation_id=target.generation_id and p.name='롱레인지 4WD');

-- EV6
with target as (select g.id generation_id from public.generations g join public.car_models cm on cm.id=g.car_model_id join public.manufacturers mf on mf.id=cm.manufacturer_id where mf.name in ('기아','Kia') and cm.name='EV6' and g.current=true limit 1)
insert into public.powertrains (generation_id,name,fuel_type,max_power_ps,battery_kwh)
select generation_id,'스탠다드 2WD','전기',170,62.9 from target where not exists (select 1 from public.powertrains p where p.generation_id=target.generation_id and p.name='스탠다드 2WD');

with target as (select g.id generation_id from public.generations g join public.car_models cm on cm.id=g.car_model_id join public.manufacturers mf on mf.id=cm.manufacturer_id where mf.name in ('기아','Kia') and cm.name='EV6' and g.current=true limit 1)
insert into public.powertrains (generation_id,name,fuel_type,max_power_ps,battery_kwh)
select generation_id,'롱레인지 2WD','전기',229,84.0 from target where not exists (select 1 from public.powertrains p where p.generation_id=target.generation_id and p.name='롱레인지 2WD');

with target as (select g.id generation_id from public.generations g join public.car_models cm on cm.id=g.car_model_id join public.manufacturers mf on mf.id=cm.manufacturer_id where mf.name in ('기아','Kia') and cm.name='EV6' and g.current=true limit 1)
insert into public.powertrains (generation_id,name,fuel_type,max_power_ps,battery_kwh)
select generation_id,'롱레인지 4WD','전기',325,84.0 from target where not exists (select 1 from public.powertrains p where p.generation_id=target.generation_id and p.name='롱레인지 4WD');

-- EV9
with target as (select g.id generation_id from public.generations g join public.car_models cm on cm.id=g.car_model_id join public.manufacturers mf on mf.id=cm.manufacturer_id where mf.name in ('기아','Kia') and cm.name='EV9' and g.current=true limit 1)
insert into public.powertrains (generation_id,name,fuel_type,max_power_ps,battery_kwh)
select generation_id,'스탠다드 2WD','전기',218,76.1 from target where not exists (select 1 from public.powertrains p where p.generation_id=target.generation_id and p.name='스탠다드 2WD');

with target as (select g.id generation_id from public.generations g join public.car_models cm on cm.id=g.car_model_id join public.manufacturers mf on mf.id=cm.manufacturer_id where mf.name in ('기아','Kia') and cm.name='EV9' and g.current=true limit 1)
insert into public.powertrains (generation_id,name,fuel_type,max_power_ps,battery_kwh)
select generation_id,'롱레인지 2WD','전기',204,99.8 from target where not exists (select 1 from public.powertrains p where p.generation_id=target.generation_id and p.name='롱레인지 2WD');

with target as (select g.id generation_id from public.generations g join public.car_models cm on cm.id=g.car_model_id join public.manufacturers mf on mf.id=cm.manufacturer_id where mf.name in ('기아','Kia') and cm.name='EV9' and g.current=true limit 1)
insert into public.powertrains (generation_id,name,fuel_type,max_power_ps,battery_kwh)
select generation_id,'롱레인지 4WD','전기',384,99.8 from target where not exists (select 1 from public.powertrains p where p.generation_id=target.generation_id and p.name='롱레인지 4WD');

-- Powertrain-specific representative official efficiency rows.
insert into public.vehicle_specs (generation_id,powertrain_id,length_mm,width_mm,height_mm,wheelbase_mm,combined_efficiency,source_url,verified_at)
select p.generation_id,p.id,4300,1850,1560,2680,'5.2 km/kWh (17인치)','https://www.kia.com/kr/vehicles/ev3/specification','2026-08-31' from public.powertrains p join public.generations g on g.id=p.generation_id join public.car_models cm on cm.id=g.car_model_id where cm.name='EV3' and p.name='스탠다드 2WD' and not exists(select 1 from public.vehicle_specs s where s.powertrain_id=p.id);
insert into public.vehicle_specs (generation_id,powertrain_id,length_mm,width_mm,height_mm,wheelbase_mm,combined_efficiency,source_url,verified_at)
select p.generation_id,p.id,4695,1880,1550,2900,'5.5 km/kWh (19인치)','https://www.kia.com/kr/vehicles/ev6/specification','2026-08-31' from public.powertrains p join public.generations g on g.id=p.generation_id join public.car_models cm on cm.id=g.car_model_id where cm.name='EV6' and p.name='스탠다드 2WD' and not exists(select 1 from public.vehicle_specs s where s.powertrain_id=p.id);
insert into public.vehicle_specs (generation_id,powertrain_id,length_mm,width_mm,height_mm,wheelbase_mm,combined_efficiency,source_url,verified_at)
select p.generation_id,p.id,5010,1980,1755,3100,'4.2 km/kWh (19인치)','https://www.kia.com/kr/vehicles/ev9/specification','2026-08-31' from public.powertrains p join public.generations g on g.id=p.generation_id join public.car_models cm on cm.id=g.car_model_id where cm.name='EV9' and p.name='스탠다드 2WD' and not exists(select 1 from public.vehicle_specs s where s.powertrain_id=p.id);

commit;
