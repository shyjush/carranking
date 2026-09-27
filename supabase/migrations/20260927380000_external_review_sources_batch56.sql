begin;

with src(brand,model,generation_code,source_name,title,url,published_date,author_label,powertrain,summary) as (
values
('KGM','무쏘','Q300','연합뉴스',
 '[시승기] 한국형 픽업의 새로운 가능성을 보다…KGM 무쏘',
 'https://www.yna.co.kr/view/AKR20260212100000003',
 date '2026-02-12','김보경','2.2 디젤 / 2.0T 가솔린',
 'Q300 신형 무쏘의 디젤과 가솔린 모델을 서울~파주 구간에서 각각 실제 주행하며 가속·승차감·조향·연비·적재공간을 평가한 독립 시승자료.'),

('KGM','토레스 EVX',null,'뉴스핌',
 '[시승기] KGM의 대안 토레스 EVX, 가성비 최고다',
 'https://www.newspim.com/news/view/20240607000608',
 date '2024-06-09','채송무','Torres EVX',
 '토레스 EVX를 서울과 경기 일대 약 120km 주행하며 공간·가속·코너링·주행거리·소프트웨어와 가격 경쟁력을 평가한 독립 시승자료.')
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
join public.generations g on g.car_model_id=cm.id
 and ((s.generation_code is null and g.current=true) or g.generation_code=s.generation_code)
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
