begin;

-- Mercedes-Benz E-Class W214: official Korean-market 2024 launch evidence.
-- Source: Mercedes-Benz Korea launch release dated 2024-01-19.
-- Insert only the exact generation/powertrain/trim and never overwrite existing approved rows.

with target as (
  select g.id as generation_id
  from public.generations g
  join public.car_models cm on cm.id = g.car_model_id
  join public.manufacturers mf on mf.id = cm.manufacturer_id
  where mf.name in ('메르세데스-벤츠','Mercedes-Benz')
    and cm.name = 'E-클래스'
    and g.generation_code = 'W214'
    and g.start_year = 2024
  limit 1
)
insert into public.powertrains
  (generation_id, name, fuel_type, displacement_cc, max_power_ps, max_torque_kgfm)
select generation_id, 'E 300 4MATIC EXCLUSIVE', '가솔린', 1999, 258, 40.8
from target
where not exists (
  select 1 from public.powertrains p
  where p.generation_id = target.generation_id
    and p.name = 'E 300 4MATIC EXCLUSIVE'
);

with target as (
  select p.id as powertrain_id
  from public.powertrains p
  join public.generations g on g.id = p.generation_id
  join public.car_models cm on cm.id = g.car_model_id
  join public.manufacturers mf on mf.id = cm.manufacturer_id
  where mf.name in ('메르세데스-벤츠','Mercedes-Benz')
    and cm.name = 'E-클래스'
    and g.generation_code = 'W214'
    and g.start_year = 2024
    and p.name = 'E 300 4MATIC EXCLUSIVE'
  limit 1
)
insert into public.trims
  (powertrain_id, model_year, name, price_krw, price_basis, source_url, verified_at)
select powertrain_id, 2024, 'E 300 4MATIC 익스클루시브', 89900000,
       'VAT 포함; 메르세데스-벤츠 코리아 2024-01-19 공식 출시자료',
       'https://www.mercedes-benz.co.kr/passengercars/brand/news-events/news-story/2024/news-20240123.html',
       date '2026-10-18'
from target
where not exists (
  select 1 from public.trims t
  where t.powertrain_id = target.powertrain_id
    and t.model_year = 2024
    and t.name = 'E 300 4MATIC 익스클루시브'
);

with target as (
  select p.id as powertrain_id, p.generation_id
  from public.powertrains p
  join public.generations g on g.id = p.generation_id
  join public.car_models cm on cm.id = g.car_model_id
  join public.manufacturers mf on mf.id = cm.manufacturer_id
  where mf.name in ('메르세데스-벤츠','Mercedes-Benz')
    and cm.name = 'E-클래스'
    and g.generation_code = 'W214'
    and g.start_year = 2024
    and p.name = 'E 300 4MATIC EXCLUSIVE'
  limit 1
)
insert into public.vehicle_specs
  (generation_id, powertrain_id, length_mm, width_mm, height_mm, wheelbase_mm,
   combined_efficiency, source_url, verified_at)
select generation_id, powertrain_id, 4955, 1880, 1475, 2960,
       '11.6 km/L (복합)',
       'https://www.mercedes-benz.co.kr/passengercars/brand/news-events/news-story/2024/news-20240123.html',
       date '2026-10-18'
from target
where not exists (
  select 1 from public.vehicle_specs vs
  where vs.powertrain_id = target.powertrain_id
);

insert into public.source_records
  (entity_type, entity_id, source_url, confidence, verified_at, note)
select 'generation', g.id,
       'https://www.mercedes-benz.co.kr/passengercars/brand/news-events/news-story/2024/news-20240123.html',
       'A', date '2026-10-18',
       '메르세데스-벤츠 코리아 공식 W214 국내 출시자료. E 300 4MATIC 익스클루시브: 4,955 x 1,880 x 1,475 mm, 축거 2,960 mm.'
from public.generations g
join public.car_models cm on cm.id = g.car_model_id
join public.manufacturers mf on mf.id = cm.manufacturer_id
where mf.name in ('메르세데스-벤츠','Mercedes-Benz')
  and cm.name = 'E-클래스'
  and g.generation_code = 'W214'
  and g.start_year = 2024
  and not exists (
    select 1 from public.source_records sr
    where sr.entity_type = 'generation'
      and sr.entity_id = g.id
      and sr.source_url = 'https://www.mercedes-benz.co.kr/passengercars/brand/news-events/news-story/2024/news-20240123.html'
  );

insert into public.source_records
  (entity_type, entity_id, source_url, confidence, verified_at, note)
select 'powertrain', p.id,
       'https://www.mercedes-benz.co.kr/passengercars/brand/news-events/news-story/2024/news-20240123.html',
       'A', date '2026-10-18',
       'E 300 4MATIC 익스클루시브, 직렬 4기통 가솔린 1,999cc, 258PS, 40.8kgf.m, 48V 마일드 하이브리드, 복합연비 11.6km/L.'
from public.powertrains p
join public.generations g on g.id = p.generation_id
join public.car_models cm on cm.id = g.car_model_id
join public.manufacturers mf on mf.id = cm.manufacturer_id
where mf.name in ('메르세데스-벤츠','Mercedes-Benz')
  and cm.name = 'E-클래스'
  and g.generation_code = 'W214'
  and g.start_year = 2024
  and p.name = 'E 300 4MATIC EXCLUSIVE'
  and not exists (
    select 1 from public.source_records sr
    where sr.entity_type = 'powertrain'
      and sr.entity_id = p.id
      and sr.source_url = 'https://www.mercedes-benz.co.kr/passengercars/brand/news-events/news-story/2024/news-20240123.html'
  );

insert into public.source_records
  (entity_type, entity_id, source_url, confidence, verified_at, note)
select 'trim', t.id,
       'https://www.mercedes-benz.co.kr/passengercars/brand/news-events/news-story/2024/news-20240123.html',
       'A', date '2026-10-18',
       '2024 E 300 4MATIC 익스클루시브 공식 VAT 포함 권장소비자가격 89,900,000원.'
from public.trims t
join public.powertrains p on p.id = t.powertrain_id
join public.generations g on g.id = p.generation_id
join public.car_models cm on cm.id = g.car_model_id
join public.manufacturers mf on mf.id = cm.manufacturer_id
where mf.name in ('메르세데스-벤츠','Mercedes-Benz')
  and cm.name = 'E-클래스'
  and g.generation_code = 'W214'
  and g.start_year = 2024
  and p.name = 'E 300 4MATIC EXCLUSIVE'
  and t.model_year = 2024
  and t.name = 'E 300 4MATIC 익스클루시브'
  and not exists (
    select 1 from public.source_records sr
    where sr.entity_type = 'trim'
      and sr.entity_id = t.id
      and sr.source_url = 'https://www.mercedes-benz.co.kr/passengercars/brand/news-events/news-story/2024/news-20240123.html'
  );

commit;
