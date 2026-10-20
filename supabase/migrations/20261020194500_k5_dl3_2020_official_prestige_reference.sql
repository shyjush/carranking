-- Official K5 DL3 2.0 gasoline Prestige June 2020 price list.
-- Add original MSRP reference only. No existing metric/snapshot update or rank publication.
begin;
insert into public.trims
 (powertrain_id, model_year, name, price_krw, price_basis, source_url, verified_at)
select p.id, 2020, '프레스티지', 26400000,
 '2020-06 official Kia K5 DL3 2.0 gasoline price list, base MSRP before 70% excise-tax relief (not 25,270,000 discounted price)',
 'https://www.kia.com/content/dam/kwcms/kr/ko/files/XJF/price/price_newk5.pdf',
 date '2026-10-20'
from public.powertrains p
join public.generations g on g.id=p.generation_id
join public.car_models m on m.id=g.car_model_id
join public.manufacturers mf on mf.id=m.manufacturer_id
where mf.name='기아' and m.name='K5' and g.generation_code='DL3'
 and p.name='2.0 가솔린'
 and not exists (
   select 1 from public.trims t where t.powertrain_id=p.id
   and t.model_year=2020 and t.name='프레스티지'
 );
commit;
