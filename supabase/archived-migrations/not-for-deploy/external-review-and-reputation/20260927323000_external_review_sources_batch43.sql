begin;

-- RAV4 source-of-truth: sixth-generation XA60 replaced XA50 in Korea in June 2026.
with m as (
  select cm.id from public.car_models cm
  join public.manufacturers mf on mf.id=cm.manufacturer_id
  where mf.name='토요타' and cm.name='RAV4'
)
update public.generations
set current=false,
    end_year=case when end_year is null or end_year>2026 then 2026 else end_year end
where car_model_id in (select id from m)
  and generation_code='XA50'
  and current=true;

insert into public.generations(car_model_id,name,generation_code,start_year,end_year,current)
select cm.id,'6세대','XA60',2026,null,true
from public.car_models cm
join public.manufacturers mf on mf.id=cm.manufacturer_id
where mf.name='토요타' and cm.name='RAV4'
on conflict(car_model_id,name) do update
set generation_code='XA60',start_year=2026,end_year=null,current=true;

insert into public.source_records(entity_type,entity_id,source_url,confidence,verified_at,note)
select 'generation',g.id,
       'https://global.toyota/en/newsroom/toyota/43740895.html',
       'A',date '2026-09-27',
       'Toyota 공식 글로벌 자료가 2025-12-17 출시된 신형 RAV4를 6세대로 명시.'
from public.generations g
join public.car_models cm on cm.id=g.car_model_id
join public.manufacturers mf on mf.id=cm.manufacturer_id
where mf.name='토요타' and cm.name='RAV4' and g.generation_code='XA60'
and not exists(
  select 1 from public.source_records s
  where s.entity_type='generation' and s.entity_id=g.id
    and s.source_url='https://global.toyota/en/newsroom/toyota/43740895.html'
);

insert into public.source_records(entity_type,entity_id,source_url,confidence,verified_at,note)
select 'generation',g.id,
       'https://auto.danawa.com/auto/?Model=4803&Work=model',
       'A',date '2026-09-27',
       '국내 판매 모델의 세대 코드 XA60 및 2026-06 국내 판매 시작 확인.'
from public.generations g
join public.car_models cm on cm.id=g.car_model_id
join public.manufacturers mf on mf.id=cm.manufacturer_id
where mf.name='토요타' and cm.name='RAV4' and g.generation_code='XA60'
and not exists(
  select 1 from public.source_records s
  where s.entity_type='generation' and s.entity_id=g.id
    and s.source_url='https://auto.danawa.com/auto/?Model=4803&Work=model'
);

with refs(source_type,source_name,title,url,published_date,author_label,powertrain,summary,confidence,approval_status,owner_claimed) as (
values
('expert_road_test','오토뷰',
 'GR은 다를 줄 알았다... 2026 토요타 RAV4 PHEV 리뷰 [1284회]',
 'https://www.autoview.co.kr/ko-kr/articles/100816',
 date '2026-07-01','오토뷰 로드테스트팀','RAV4 PHEV GR SPORT',
 'XA60 6세대 RAV4 PHEV GR SPORT의 가속·제동·중량·정숙성·가격과 장단점을 계측한 전문 로드테스트.',
 'A','approved_reference',false),

('expert_road_test','연합뉴스',
 '[시승기] PHEV 주행성능 탄탄한 도요타 올 뉴 라브4',
 'https://www.yna.co.kr/amp/view/AKR20260619168700003',
 date '2026-06-20','김윤구','RAV4 HEV / PHEV',
 'XA60 6세대 HEV와 PHEV를 국내 미디어 시승행사에서 실제 주행해 가속·소음·핸들링·효율을 비교 평가한 독립 시승자료.',
 'B','approved_reference',false),

('owner_report_unverified','오토뷰 내 차를 소개합니다',
 '2026 RAV4 PHEV XSE 한 달 주행 경험을 공유합니다.',
 'https://www.autoview.co.kr/ko-kr/boards/3/79153',
 date '2026-08-11','naver_5ewdsl07','RAV4 PHEV XSE',
 '작성자가 국내 사전예약 후 XA60 RAV4 PHEV를 인수해 한 달 운용하며 EV/HV 운용·연비·승차감·공간·원격공조·사운드 경험을 공유한 글.',
 'C','hold',true)
)
insert into public.external_review_sources(
 generation_id,source_type,source_name,title,canonical_url,published_date,observed_date,
 author_label,powertrain_hint,summary,source_confidence,approval_status,dedupe_status,
 owner_claimed,owner_verified,owner_score_eligible,value_score_eligible)
select g.id,r.source_type,r.source_name,r.title,r.url,r.published_date,date '2026-09-27',
 r.author_label,r.powertrain,r.summary,r.confidence,r.approval_status,'unique',
 r.owner_claimed,false,false,false
from refs r
join public.generations g on g.generation_code='XA60'
join public.car_models cm on cm.id=g.car_model_id and cm.name='RAV4'
join public.manufacturers mf on mf.id=cm.manufacturer_id and mf.name='토요타'
on conflict(canonical_url) do update set
 generation_id=excluded.generation_id,
 source_type=excluded.source_type,
 source_name=excluded.source_name,
 title=excluded.title,
 published_date=excluded.published_date,
 observed_date=excluded.observed_date,
 author_label=excluded.author_label,
 powertrain_hint=excluded.powertrain_hint,
 summary=excluded.summary,
 source_confidence=excluded.source_confidence,
 approval_status=excluded.approval_status,
 dedupe_status='unique',
 owner_claimed=excluded.owner_claimed,
 owner_verified=false,
 owner_score_eligible=false,
 value_score_eligible=false,
 updated_at=now();

commit;
