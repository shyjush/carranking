begin;

with src(brand,model,generation_code,source_name,title,url,published_date,author_label,powertrain,summary) as (
values
('BMW','i4','G26','연합뉴스',
 '[시승기] 역동적인 외관에 뛰어난 가속성능…BMW 순수전기 그란쿠페 i4',
 'https://www.yna.co.kr/amp/view/AKR20220401158300003',
 date '2022-04-02','권희원','i4 eDrive40 / M50',
 'G26 i4를 영종도 드라이빙센터~인천공항전망대~강화도 구간에서 실제 주행하며 가속·회생제동·핸들링·실내와 주행거리를 평가한 독립 시승자료.'),

('BMW','i5','G60','연합뉴스',
 '[시승기] BMW의 자존심 드디어 전기차로…미리 타본 5시리즈 i5',
 'https://www.yna.co.kr/view/AKR20231002002600003',
 date '2023-10-02','임기창','i5 eDrive40 / M60 xDrive',
 'G60 i5를 포르투갈 일반도로와 교량·시골길에서 최대 약 180km 주행하며 전비·공간·고속안정성·승차감과 고성능 M60 특성을 평가한 독립 시승자료.'),

('BMW','X3','G45','연합뉴스',
 '[시승기] 더 강해지고 똑똑해졌다…BMW 간판 SUV 뉴 X3',
 'https://www.yna.co.kr/amp/view/AKR20241005044800003',
 date '2024-10-07','한상용','X3 20 / M50 xDrive',
 'G45 신형 X3를 뮌헨 외곽 약 120km 일반도로와 아우토반에서 주행하며 가속·감속·승차감·고속안정성·공간을 평가한 독립 시승자료.')
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
