begin;

-- Deployment is idempotent; remote history is synchronized read-only in CI before push.

-- Toyota RAV4 XA60: official Korean-market 2026 HEV LIMITED evidence.
-- Source page states the material is based on July 2026 specifications.
-- Match the exact manufacturer/model/generation/year and never overwrite existing approved rows.

with target as (
  select g.id as generation_id
  from public.generations g
  join public.car_models cm on cm.id = g.car_model_id
  join public.manufacturers mf on mf.id = cm.manufacturer_id
  where mf.name in ('토요타','Toyota')
    and cm.name = 'RAV4'
    and g.generation_code = 'XA60'
    and g.start_year = 2026
  limit 1
)
insert into public.powertrains
  (generation_id, name, fuel_type, displacement_cc, max_power_ps, max_torque_kgfm)
select generation_id, '2.5 HEV AWD LIMITED', '하이브리드', 2487, 239, 22.5
from target
where not exists (
  select 1 from public.powertrains p
  where p.generation_id = target.generation_id
    and p.name = '2.5 HEV AWD LIMITED'
);

with target as (
  select p.id as powertrain_id, p.generation_id
  from public.powertrains p
  join public.generations g on g.id = p.generation_id
  join public.car_models cm on cm.id = g.car_model_id
  join public.manufacturers mf on mf.id = cm.manufacturer_id
  where mf.name in ('토요타','Toyota')
    and cm.name = 'RAV4'
    and g.generation_code = 'XA60'
    and g.start_year = 2026
    and p.name = '2.5 HEV AWD LIMITED'
  limit 1
)
insert into public.trims
  (powertrain_id, model_year, name, price_krw, price_basis, source_url, verified_at)
select powertrain_id, 2026, 'HEV LIMITED', 58200000,
       'VAT 포함; 한국토요타 공식 페이지 2026년 7월 기준',
       'https://www.toyota.co.kr/models/rav4hev/', date '2026-10-16'
from target
where not exists (
  select 1 from public.trims t
  where t.powertrain_id = target.powertrain_id
    and t.model_year = 2026
    and t.name = 'HEV LIMITED'
);

with target as (
  select p.id as powertrain_id, p.generation_id
  from public.powertrains p
  join public.generations g on g.id = p.generation_id
  join public.car_models cm on cm.id = g.car_model_id
  join public.manufacturers mf on mf.id = cm.manufacturer_id
  where mf.name in ('토요타','Toyota')
    and cm.name = 'RAV4'
    and g.generation_code = 'XA60'
    and g.start_year = 2026
    and p.name = '2.5 HEV AWD LIMITED'
  limit 1
)
insert into public.vehicle_specs
  (generation_id, powertrain_id, length_mm, width_mm, height_mm, wheelbase_mm,
   combined_efficiency, source_url, verified_at)
select generation_id, powertrain_id, 4600, 1855, 1680, 2690,
       '15.6 km/L (복합)',
       'https://www.toyota.co.kr/models/rav4hev/', date '2026-10-16'
from target
where not exists (
  select 1 from public.vehicle_specs vs
  where vs.powertrain_id = target.powertrain_id
);

insert into public.source_records
  (entity_type, entity_id, source_url, confidence, verified_at, note)
select 'generation', g.id,
       'https://www.toyota.co.kr/models/rav4hev/',
       'A', date '2026-10-16',
       '한국토요타 공식 2026년 7월 자료. RAV4 XA60 HEV LIMITED: 4,600 x 1,855 x 1,680 mm, 축거 2,690 mm.'
from public.generations g
join public.car_models cm on cm.id = g.car_model_id
join public.manufacturers mf on mf.id = cm.manufacturer_id
where mf.name in ('토요타','Toyota')
  and cm.name = 'RAV4'
  and g.generation_code = 'XA60'
  and g.start_year = 2026
  and not exists (
    select 1 from public.source_records sr
    where sr.entity_type = 'generation'
      and sr.entity_id = g.id
      and sr.source_url = 'https://www.toyota.co.kr/models/rav4hev/'
  );

insert into public.source_records
  (entity_type, entity_id, source_url, confidence, verified_at, note)
select 'powertrain', p.id,
       'https://www.toyota.co.kr/models/rav4hev/',
       'A', date '2026-10-16',
       '2.5L HEV AWD LIMITED, 배기량 2,487cc, 시스템 총출력 239PS, 엔진 최대토크 22.5kg.m, 복합연비 15.6km/L.'
from public.powertrains p
join public.generations g on g.id = p.generation_id
join public.car_models cm on cm.id = g.car_model_id
join public.manufacturers mf on mf.id = cm.manufacturer_id
where mf.name in ('토요타','Toyota')
  and cm.name = 'RAV4'
  and g.generation_code = 'XA60'
  and g.start_year = 2026
  and p.name = '2.5 HEV AWD LIMITED'
  and not exists (
    select 1 from public.source_records sr
    where sr.entity_type = 'powertrain'
      and sr.entity_id = p.id
      and sr.source_url = 'https://www.toyota.co.kr/models/rav4hev/'
  );

insert into public.source_records
  (entity_type, entity_id, source_url, confidence, verified_at, note)
select 'trim', t.id,
       'https://www.toyota.co.kr/models/rav4hev/',
       'A', date '2026-10-16',
       '2026 RAV4 HEV LIMITED 공식 VAT 포함 가격 58,200,000원.'
from public.trims t
join public.powertrains p on p.id = t.powertrain_id
join public.generations g on g.id = p.generation_id
join public.car_models cm on cm.id = g.car_model_id
join public.manufacturers mf on mf.id = cm.manufacturer_id
where mf.name in ('토요타','Toyota')
  and cm.name = 'RAV4'
  and g.generation_code = 'XA60'
  and g.start_year = 2026
  and p.name = '2.5 HEV AWD LIMITED'
  and t.model_year = 2026
  and t.name = 'HEV LIMITED'
  and not exists (
    select 1 from public.source_records sr
    where sr.entity_type = 'trim'
      and sr.entity_id = t.id
      and sr.source_url = 'https://www.toyota.co.kr/models/rav4hev/'
  );

commit;
