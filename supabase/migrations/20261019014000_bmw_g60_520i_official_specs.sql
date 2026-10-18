begin;

-- BMW 5 Series G60: official Korean-market 2024 launch evidence.
-- Insert only the exact generation/powertrain/trim and never overwrite existing approved rows.

with target as (
  select g.id as generation_id
  from public.generations g
  join public.car_models cm on cm.id = g.car_model_id
  join public.manufacturers mf on mf.id = cm.manufacturer_id
  where mf.name = 'BMW'
    and cm.name = '5시리즈'
    and g.generation_code = 'G60'
    and g.start_year = 2024
  limit 1
)
insert into public.powertrains
  (generation_id, name, fuel_type, displacement_cc, max_power_ps, max_torque_kgfm)
select generation_id, '520i', '가솔린', 1998, 190, 31.6
from target
where not exists (
  select 1 from public.powertrains p
  where p.generation_id = target.generation_id
    and p.name = '520i'
);

with target as (
  select p.id as powertrain_id
  from public.powertrains p
  join public.generations g on g.id = p.generation_id
  join public.car_models cm on cm.id = g.car_model_id
  join public.manufacturers mf on mf.id = cm.manufacturer_id
  where mf.name = 'BMW'
    and cm.name = '5시리즈'
    and g.generation_code = 'G60'
    and g.start_year = 2024
    and p.name = '520i'
  limit 1
)
insert into public.trims
  (powertrain_id, model_year, name, price_krw, price_basis, source_url, verified_at)
select powertrain_id, 2024, '520i', 68800000,
       'VAT 포함; BMW 코리아 2023-10-05 공식 국내 출시자료의 520i 시작가',
       'https://www.press.bmwgroup.com/korea/article/detail/T0437677KO/bmw-%EC%BD%94%EB%A6%AC%EC%95%84-%EC%B0%A8%EC%84%B8%EB%8C%80-%ED%94%84%EB%A6%AC%EB%AF%B8%EC%97%84-%EC%84%B8%EB%8B%A8-%EB%89%B4-5%EC%8B%9C%EB%A6%AC%EC%A6%88%E2%80%99-%EC%A0%84-%EC%84%B8%EA%B3%84-%EC%B5%9C%EC%B4%88%EB%A1%9C-%EA%B5%AD%EB%82%B4-%EC%B6%9C%EC%8B%9C?language=ko',
       date '2026-10-19'
from target
where not exists (
  select 1 from public.trims t
  where t.powertrain_id = target.powertrain_id
    and t.model_year = 2024
    and t.name = '520i'
);

with target as (
  select p.id as powertrain_id, p.generation_id
  from public.powertrains p
  join public.generations g on g.id = p.generation_id
  join public.car_models cm on cm.id = g.car_model_id
  join public.manufacturers mf on mf.id = cm.manufacturer_id
  where mf.name = 'BMW'
    and cm.name = '5시리즈'
    and g.generation_code = 'G60'
    and g.start_year = 2024
    and p.name = '520i'
  limit 1
)
insert into public.vehicle_specs
  (generation_id, powertrain_id, length_mm, width_mm, height_mm, wheelbase_mm,
   combined_efficiency, source_url, verified_at)
select generation_id, powertrain_id, 5060, 1900, 1515, 2995,
       '12.1 km/L (복합)',
       'https://www.press.bmwgroup.com/united-kingdom/article/attachment/T0418899EN_GB/613060',
       date '2026-10-19'
from target
where not exists (
  select 1 from public.vehicle_specs vs
  where vs.powertrain_id = target.powertrain_id
);

insert into public.source_records
  (entity_type, entity_id, source_url, confidence, verified_at, note)
select 'generation', g.id,
       'https://www.press.bmwgroup.com/united-kingdom/article/attachment/T0418899EN_GB/613060',
       'A', date '2026-10-19',
       'BMW 그룹 공식 G60 기술자료. 5,060 x 1,900 x 1,515 mm, 축거 2,995 mm.'
from public.generations g
join public.car_models cm on cm.id = g.car_model_id
join public.manufacturers mf on mf.id = cm.manufacturer_id
where mf.name = 'BMW'
  and cm.name = '5시리즈'
  and g.generation_code = 'G60'
  and g.start_year = 2024
  and not exists (
    select 1 from public.source_records sr
    where sr.entity_type = 'generation'
      and sr.entity_id = g.id
      and sr.source_url = 'https://www.press.bmwgroup.com/united-kingdom/article/attachment/T0418899EN_GB/613060'
  );

insert into public.source_records
  (entity_type, entity_id, source_url, confidence, verified_at, note)
select 'powertrain', p.id,
       'https://www.press.bmwgroup.com/greece/article/attachment/T0439092EL/610471',
       'A', date '2026-10-19',
       'BMW 그룹 공식 G60 가격·기술자료. 520i 배기량 1,998cc.'
from public.powertrains p
join public.generations g on g.id = p.generation_id
join public.car_models cm on cm.id = g.car_model_id
join public.manufacturers mf on mf.id = cm.manufacturer_id
where mf.name = 'BMW'
  and cm.name = '5시리즈'
  and g.generation_code = 'G60'
  and g.start_year = 2024
  and p.name = '520i'
  and not exists (
    select 1 from public.source_records sr
    where sr.entity_type = 'powertrain'
      and sr.entity_id = p.id
      and sr.source_url = 'https://www.press.bmwgroup.com/greece/article/attachment/T0439092EL/610471'
  );

insert into public.source_records
  (entity_type, entity_id, source_url, confidence, verified_at, note)
select 'powertrain', p.id,
       'https://www.bmw.co.kr/ko/all-models/5-series/sedan/bmw-5-series-sedan-overview.html',
       'A', date '2026-10-19',
       'BMW 코리아 공식 G60 모델정보. 520i: 4기통 가솔린 터보, 190PS, 31.6kgf.m, 48V 마일드 하이브리드, 복합연비 12.1km/L. 배기량 1,998cc는 BMW 그룹 공식 G60 가격·기술자료로 교차 확인.'
from public.powertrains p
join public.generations g on g.id = p.generation_id
join public.car_models cm on cm.id = g.car_model_id
join public.manufacturers mf on mf.id = cm.manufacturer_id
where mf.name = 'BMW'
  and cm.name = '5시리즈'
  and g.generation_code = 'G60'
  and g.start_year = 2024
  and p.name = '520i'
  and not exists (
    select 1 from public.source_records sr
    where sr.entity_type = 'powertrain'
      and sr.entity_id = p.id
      and sr.source_url = 'https://www.bmw.co.kr/ko/all-models/5-series/sedan/bmw-5-series-sedan-overview.html'
  );

insert into public.source_records
  (entity_type, entity_id, source_url, confidence, verified_at, note)
select 'trim', t.id,
       'https://www.press.bmwgroup.com/korea/article/detail/T0437677KO/bmw-%EC%BD%94%EB%A6%AC%EC%95%84-%EC%B0%A8%EC%84%B8%EB%8C%80-%ED%94%84%EB%A6%AC%EB%AF%B8%EC%97%84-%EC%84%B8%EB%8B%A8-%EB%89%B4-5%EC%8B%9C%EB%A6%AC%EC%A6%88%E2%80%99-%EC%A0%84-%EC%84%B8%EA%B3%84-%EC%B5%9C%EC%B4%88%EB%A1%9C-%EA%B5%AD%EB%82%B4-%EC%B6%9C%EC%8B%9C?language=ko',
       'A', date '2026-10-19',
       'BMW 코리아 공식 2023-10-05 국내 출시자료. 2024형 뉴 520i 공식 시작가 68,800,000원.'
from public.trims t
join public.powertrains p on p.id = t.powertrain_id
join public.generations g on g.id = p.generation_id
join public.car_models cm on cm.id = g.car_model_id
join public.manufacturers mf on mf.id = cm.manufacturer_id
where mf.name = 'BMW'
  and cm.name = '5시리즈'
  and g.generation_code = 'G60'
  and g.start_year = 2024
  and p.name = '520i'
  and t.model_year = 2024
  and t.name = '520i'
  and not exists (
    select 1 from public.source_records sr
    where sr.entity_type = 'trim'
      and sr.entity_id = t.id
      and sr.source_url = 'https://www.press.bmwgroup.com/korea/article/detail/T0437677KO/bmw-%EC%BD%94%EB%A6%AC%EC%95%84-%EC%B0%A8%EC%84%B8%EB%8C%80-%ED%94%84%EB%A6%AC%EB%AF%B8%EC%97%84-%EC%84%B8%EB%8B%A8-%EB%89%B4-5%EC%8B%9C%EB%A6%AC%EC%A6%88%E2%80%99-%EC%A0%84-%EC%84%B8%EA%B3%84-%EC%B5%9C%EC%B4%88%EB%A1%9C-%EA%B5%AD%EB%82%B4-%EC%B6%9C%EC%8B%9C?language=ko'
  );

commit;
