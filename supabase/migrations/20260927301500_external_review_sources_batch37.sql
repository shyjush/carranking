begin;

with src(brand,model,generation_code,source_name,title,url,published_date,author_label,powertrain,summary) as (
values
('르노코리아','SM3','N17','동아일보',
 '[자동차 시승기] SM3…부드러운 핸들링, 순발력은 다소',
 'https://www.donga.com/news/amp/all/20021118/7883678/9',
 date '2002-11-18',null,'1.5 가솔린',
 'N17 1세대 SM3 출시 초기 실제 시승기사. 핸들링·가속 반응·실내 마감과 주행 특성을 독립적으로 평가한 자료.'),

('현대','아반떼','HD','주간경향',
 '[CAR] 신형 아반떼 시승기',
 'https://weekly.khan.co.kr/series/ne003/?page=5',
 date '2006-10-17',null,'1.6 VVT 프리미어',
 'HD 아반떼 출시 초기 실제 시승기사. 승차감·안전성·엔진음·조향·브레이크·핸들링과 직진 안정성을 평가한 독립 자료.')
)
insert into public.external_review_sources(
 generation_id,source_type,source_name,title,canonical_url,published_date,observed_date,
 author_label,powertrain_hint,summary,source_confidence,approval_status,dedupe_status,
 owner_claimed,owner_verified,owner_score_eligible,value_score_eligible)
select g.id,'expert_road_test',s.source_name,s.title,s.url,s.published_date,date '2026-09-27',
 s.author_label,s.powertrain,s.summary,'B','approved_reference','unique',false,false,false,false
from src s
join public.manufacturers mf on mf.name=s.brand
join public.car_models cm on cm.manufacturer_id=mf.id and cm.name=s.model
join public.generations g on g.car_model_id=cm.id and g.generation_code=s.generation_code
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
