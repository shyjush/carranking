begin;

-- Seltos source-of-truth: second-generation SP3 replaced first-generation SP2 in Korea in 2026.
with m as (
  select cm.id
  from public.car_models cm
  join public.manufacturers mf on mf.id=cm.manufacturer_id
  where mf.name='기아' and cm.name='셀토스'
)
update public.generations
set current=false,
    end_year=case when end_year is null or end_year>2025 then 2025 else end_year end
where car_model_id in (select id from m)
  and generation_code='SP2'
  and current=true;

insert into public.generations(car_model_id,name,generation_code,start_year,end_year,current)
select cm.id,'2세대','SP3',2026,null,true
from public.car_models cm
join public.manufacturers mf on mf.id=cm.manufacturer_id
where mf.name='기아' and cm.name='셀토스'
on conflict(car_model_id,name) do update
set generation_code='SP3',start_year=2026,end_year=null,current=true;

insert into public.source_records(entity_type,entity_id,source_url,confidence,verified_at,note)
select 'generation',g.id,
       'https://www3.epa.gov/otaq/datafiles/CSI-VKMXV01.6NC3-VKMXR0125NCG.PDF',
       'A',date '2026-09-27',
       '미국 EPA 2027 Seltos 인증자료에서 차량 구성/Leak Family가 SP3로 확인됨.'
from public.generations g
join public.car_models cm on cm.id=g.car_model_id
join public.manufacturers mf on mf.id=cm.manufacturer_id
where mf.name='기아' and cm.name='셀토스' and g.generation_code='SP3'
and not exists (
  select 1 from public.source_records s
  where s.entity_type='generation'
    and s.entity_id=g.id
    and s.source_url='https://www3.epa.gov/otaq/datafiles/CSI-VKMXV01.6NC3-VKMXR0125NCG.PDF'
);

insert into public.source_records(entity_type,entity_id,source_url,confidence,verified_at,note)
select 'generation',g.id,
       'https://www.kia.com/kr/vehicles/seltos/specification',
       'A',date '2026-09-27',
       '기아 공식 국내 현행 셀토스 제원 페이지. 1.6 터보/1.6 하이브리드 현행 판매 사양 확인.'
from public.generations g
join public.car_models cm on cm.id=g.car_model_id
join public.manufacturers mf on mf.id=cm.manufacturer_id
where mf.name='기아' and cm.name='셀토스' and g.generation_code='SP3'
and not exists (
  select 1 from public.source_records s
  where s.entity_type='generation'
    and s.entity_id=g.id
    and s.source_url='https://www.kia.com/kr/vehicles/seltos/specification'
);

with refs(source_name,title,url,published_date,author_label,powertrain,summary) as (
values
('연합뉴스',
 '[시승기] 디자인·성능·편의사양 모두 업…기아 2세대 셀토스',
 'https://www.yna.co.kr/view/AKR20260129029500003',
 date '2026-01-29','김보경','1.6 하이브리드 / 1.6 터보',
 'SP3 2세대 셀토스를 서울~춘천 약 150km 주행해 공간·하이브리드/터보 성능·조향·ADAS·연비와 가격을 평가한 독립 시승자료.'),

('뉴스핌',
 '[시승기] 기아 디 올 뉴 셀토스, 달리기보다 일상을 택한 도심형 SUV',
 'https://www.newspim.com/news/view/20260128001079',
 date '2026-01-29','이찬우','1.6 하이브리드',
 'SP3 2세대 디 올 뉴 셀토스 하이브리드의 정숙성·연비·일상 승차감·출력과 편의성을 평가한 독립 미디어 시승자료.')
)
insert into public.external_review_sources(
 generation_id,source_type,source_name,title,canonical_url,published_date,observed_date,
 author_label,powertrain_hint,summary,source_confidence,approval_status,dedupe_status,
 owner_claimed,owner_verified,owner_score_eligible,value_score_eligible)
select g.id,'expert_road_test',r.source_name,r.title,r.url,r.published_date,date '2026-09-27',
 r.author_label,r.powertrain,r.summary,'B','approved_reference','unique',false,false,false,false
from refs r
join public.generations g on g.generation_code='SP3'
join public.car_models cm on cm.id=g.car_model_id and cm.name='셀토스'
join public.manufacturers mf on mf.id=cm.manufacturer_id and mf.name='기아'
on conflict(canonical_url) do update set
 generation_id=excluded.generation_id,
 source_type='expert_road_test',
 source_name=excluded.source_name,
 title=excluded.title,
 published_date=excluded.published_date,
 observed_date=excluded.observed_date,
 author_label=excluded.author_label,
 powertrain_hint=excluded.powertrain_hint,
 summary=excluded.summary,
 source_confidence='B',
 approval_status='approved_reference',
 dedupe_status='unique',
 owner_score_eligible=false,
 value_score_eligible=false,
 updated_at=now();

commit;
