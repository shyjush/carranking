begin;

with src(brand,model,generation_code,source_name,title,url,published_date,author_label,powertrain,summary) as (
values
('현대','쏘나타','DN8','연합뉴스',
 '[시승기] 확 달라진 국민차 쏘나타 디엣지…세단 인기 살릴까',
 'https://www.yna.co.kr/amp/view/AKR20230511168300003',
 date '2023-05-12','김보경','쏘나타 디 엣지',
 'DN8 부분변경 쏘나타 디 엣지를 실제 도로에서 주행해 디자인·가속·승차감·공간과 세단 상품성을 평가한 독립 시승자료.'),

('현대','투싼','NX4','연합뉴스',
 '[시승기] 확 바뀐 실내·무난한 주행감…더 뉴 투싼',
 'https://www.yna.co.kr/view/AKR20231221163300003',
 date '2023-12-24','이승연','1.6T 가솔린 2WD',
 'NX4 부분변경 더 뉴 투싼을 실제 도로에서 주행해 실내·가속·주행감·편의사양과 공간을 평가한 독립 시승자료.'),

('현대','코나','SX2','연합뉴스',
 '[시승기] 소형SUV 한계 넘은 신형 코나…안정성 기대 이상',
 'https://www.yna.co.kr/view/AKR20230128034900003',
 date '2023-01-29','최평천','1.6T 가솔린',
 'SX2 신형 코나를 실제 도로에서 주행해 가속·스포츠모드·안정성·연비·주행보조와 가격을 평가한 독립 시승자료.'),

('현대','스타리아','US4','연합뉴스',
 '[시승기] 넓고 조용하다…현대차 스타리아 하이브리드',
 'https://www.yna.co.kr/view/AKR20240322020500003',
 date '2024-03-22','김보경','1.6T 하이브리드 라운지 7인승',
 'US4 스타리아 하이브리드를 쇼퍼·직접 운전으로 체험해 공간·승차감·정숙성·가속·연비를 평가한 독립 시승자료.'),

('현대','캐스퍼','AX1','연합뉴스',
 '[시승기] 소형차 단점 개선한 캐스퍼 일렉트릭…전기차 캐즘 뚫을까',
 'https://www.yna.co.kr/view/AKR20240821154800003',
 date '2024-08-22','김보경','캐스퍼 일렉트릭',
 'AX1 캐스퍼 일렉트릭을 고양~파주 약 50km 주행해 공간·가속·승차감·소음·전비와 안전보조를 평가한 독립 시승자료.')
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
