begin;

-- Official Kia current-model expansion: EV4 + EV5.
-- Sources verified 2026-08-31 from Kia Korea current specification/price pages.

insert into public.car_models(manufacturer_id,name,slug,category)
select mf.id,'EV4','ev4','전기 승용'
from public.manufacturers mf
where mf.name='기아'
and not exists(select 1 from public.car_models cm where cm.manufacturer_id=mf.id and cm.name='EV4');

insert into public.car_models(manufacturer_id,name,slug,category)
select mf.id,'EV5','ev5','전기 SUV'
from public.manufacturers mf
where mf.name='기아'
and not exists(select 1 from public.car_models cm where cm.manufacturer_id=mf.id and cm.name='EV5');

insert into public.generations(car_model_id,name,generation_code,start_year,current)
select cm.id,'EV4',null,2025,true from public.car_models cm join public.manufacturers mf on mf.id=cm.manufacturer_id
where mf.name='기아' and cm.name='EV4' and not exists(select 1 from public.generations g where g.car_model_id=cm.id and g.current=true);

insert into public.generations(car_model_id,name,generation_code,start_year,current)
select cm.id,'EV5',null,2025,true from public.car_models cm join public.manufacturers mf on mf.id=cm.manufacturer_id
where mf.name='기아' and cm.name='EV5' and not exists(select 1 from public.generations g where g.car_model_id=cm.id and g.current=true);

insert into public.vehicle_specs(generation_id,powertrain_id,length_mm,width_mm,height_mm,wheelbase_mm,combined_efficiency,source_url,verified_at)
select g.id,null,4730,1860,1480,2820,'5.8 km/kWh (Standard 2WD 17-inch)','https://www.kia.com/kr/vehicles/ev4/specification',date '2026-08-31'
from public.generations g join public.car_models cm on cm.id=g.car_model_id join public.manufacturers mf on mf.id=cm.manufacturer_id
where mf.name='기아' and cm.name='EV4' and g.current=true
and not exists(select 1 from public.vehicle_specs vs where vs.generation_id=g.id and vs.powertrain_id is null);

insert into public.powertrains(generation_id,name,fuel_type,max_power_ps,battery_kwh)
select g.id,x.name,'전기',x.ps,x.kwh
from public.generations g join public.car_models cm on cm.id=g.car_model_id join public.manufacturers mf on mf.id=cm.manufacturer_id
cross join (values ('Standard 2WD',204::numeric,58.3::numeric),('Long Range 2WD',204::numeric,81.4::numeric),('Long Range 4WD',265::numeric,81.4::numeric)) x(name,ps,kwh)
where mf.name='기아' and cm.name='EV4' and g.current=true
and not exists(select 1 from public.powertrains p where p.generation_id=g.id and p.name=x.name);

insert into public.powertrains(generation_id,name,fuel_type,battery_kwh)
select g.id,'Standard','전기',60.3
from public.generations g join public.car_models cm on cm.id=g.car_model_id join public.manufacturers mf on mf.id=cm.manufacturer_id
where mf.name='기아' and cm.name='EV5' and g.current=true
and not exists(select 1 from public.powertrains p where p.generation_id=g.id and p.name='Standard');

insert into public.trims(powertrain_id,model_year,name,price_krw,price_before_tax_benefit_krw,price_basis,source_url,verified_at)
select p.id,2026,'Air Standard',41550000,43710000,'세제혜택 후 / 세제혜택 전','https://www.kia.com/kr/vehicles/ev5/price',date '2026-08-31'
from public.powertrains p join public.generations g on g.id=p.generation_id join public.car_models cm on cm.id=g.car_model_id join public.manufacturers mf on mf.id=cm.manufacturer_id
where mf.name='기아' and cm.name='EV5' and g.current=true and p.name='Standard'
and not exists(select 1 from public.trims t where t.powertrain_id=p.id and t.model_year=2026 and t.name='Air Standard');

insert into public.source_records(entity_type,entity_id,source_url,confidence,verified_at,note)
select 'generation',g.id,'https://www.kia.com/kr/vehicles/ev4/specification','A',date '2026-08-31','EV4 current official specifications'
from public.generations g join public.car_models cm on cm.id=g.car_model_id join public.manufacturers mf on mf.id=cm.manufacturer_id
where mf.name='기아' and cm.name='EV4' and g.current=true
and not exists(select 1 from public.source_records s where s.entity_id=g.id and s.source_url='https://www.kia.com/kr/vehicles/ev4/specification');

insert into public.source_records(entity_type,entity_id,source_url,confidence,verified_at,note)
select 'generation',g.id,'https://www.kia.com/kr/vehicles/ev5/price','A',date '2026-08-31','EV5 current official price and Standard battery capacity'
from public.generations g join public.car_models cm on cm.id=g.car_model_id join public.manufacturers mf on mf.id=cm.manufacturer_id
where mf.name='기아' and cm.name='EV5' and g.current=true
and not exists(select 1 from public.source_records s where s.entity_id=g.id and s.source_url='https://www.kia.com/kr/vehicles/ev5/price');

commit;