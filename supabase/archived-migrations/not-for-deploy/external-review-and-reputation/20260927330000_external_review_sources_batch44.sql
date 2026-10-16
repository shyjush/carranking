begin;

with src(brand,model,generation_code,use_current,source_name,title,url,published_date,author_label,powertrain,summary) as (
values
('기아','EV3','SV',false,'연합뉴스',
 '[시승기] 전기차를 편하고 효율적으로 모는 법…기아 야심작 EV3',
 'https://www.yna.co.kr/view/AKR20240725161500003',
 date '2024-07-26','임성호','EV3 롱레인지',
 'EV3 미디어 시승에서 서울~속초 약 200km를 직접 주행해 아이페달 3.0·스마트 회생·공간·전비·핸들링을 평가한 독립 시승자료.'),

('기아','EV4',null,true,'연합뉴스',
 '[시승기] 주행성능·거리 모두 만족한 전기 세단…기아 EV4',
 'https://www.yna.co.kr/view/AKR20250424033500003',
 date '2025-04-24','김보경','EV4 롱레인지',
 'EV4 롱레인지로 하남~광주 약 65km를 실제 주행해 공간·가속·승차감·회생제동·전비·소음을 평가한 독립 시승자료.'),

('기아','EV5',null,true,'연합뉴스',
 '[시승기] 스포티지 전기차 기대 충족하나…공간감 만족스러운 EV5',
 'https://www.yna.co.kr/amp/view/AKR20250924026400003',
 date '2025-09-24','김보경','EV5',
 '국내 출시 EV5를 실제 도로에서 주행해 공간·가속·안전보조·소음·가격을 평가한 독립 시승자료.'),

('기아','EV6','CV',false,'연합뉴스',
 '[시승기] 전기차 집안싸움 시작된다…기아 첫 전용 전기차 EV6',
 'https://www.yna.co.kr/view/AKR20210826166300003',
 date '2021-08-27','장하나','EV6 롱레인지 AWD',
 'EV6 롱레인지 AWD로 성수~포천 왕복 142.8km를 주행해 회생제동·전비·공간·가속·정숙성을 평가한 독립 시승자료.'),

('기아','EV9','MV',false,'연합뉴스',
 '[시승기] 플래그십 전기차 손색없다…기아 자신감 반영된 EV9',
 'https://www.yna.co.kr/view/AKR20230618045200003',
 date '2023-06-19','임기창','EV9 어스 4WD',
 'EV9 양산차로 하남~부여 약 200km를 주행해 전비·동력·승차감·ADAS·3열 공간과 가격을 평가한 독립 시승자료.'),

('현대','아이오닉 5','NE',false,'연합뉴스',
 '[시승기] 부드러운 승차감, 더 긴 주행거리…더 뉴 아이오닉5',
 'https://www.yna.co.kr/amp/view/AKR20240413031200003',
 date '2024-04-14','이승연','더 뉴 아이오닉5',
 'NE 아이오닉5 부분변경 모델을 실제 도로에서 주행해 승차감·가속 응답·전비·주행거리와 패밀리카 완성도를 평가한 독립 시승자료.')
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
 and ((not s.use_current and g.generation_code=s.generation_code) or (s.use_current and g.current=true))
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
