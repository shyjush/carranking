begin;

with src(brand,model,generation_code,source_name,title,url,published_date,author_label,powertrain,summary) as (
values
('제네시스','G90','RS4','연합뉴스',
 '[시승기] 검정의 고급감 입은 플래그십 세단…제네시스 G90 블랙',
 'https://www.yna.co.kr/view/AKR20240503119600003',
 date '2024-05-04','임성호','G90 Black 3.5T 48V e-S/C',
 'RS4 G90 블랙을 서울 시내 약 50km 주행하며 NVH·승차감·2열 쇼퍼모드와 고급 편의사양을 평가한 독립 시승자료.'),

('제네시스','GV60','JW','연합뉴스',
 '[시승기] 아픈 손가락 GV60, 고급스러움 더해 돌아왔다…승차감 돋보여',
 'https://www.yna.co.kr/view/AKR20250422153100003',
 date '2025-04-23','홍규빈','GV60 부분변경',
 'JW GV60 부분변경 모델을 서울 관악~안산 대부도 왕복 약 120km 주행하며 승차감·코너링·풍절음·전비·2열 공간을 평가한 독립 시승자료.'),

('제네시스','GV80','JX1','연합뉴스',
 '[시승기] 국내 브랜드 첫 럭셔리 SUV…제네시스 GV80',
 'https://www.yna.co.kr/view/AKR20200115175900003',
 date '2020-01-16','최윤정','GV80 3.0 디젤',
 'JX1 GV80 출시 시승에서 고양~인천 왕복 약 120km를 주행하며 NVH·승차감·가속·공간·ADAS·연비를 평가한 독립 시승자료.')
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
