begin;

with src(brand,model,generation_code,source_name,title,url,published_date,author_label,powertrain,summary) as (
values
('기아','K9','RJ','연합뉴스',
 '[시승기] 커브·내리막길 인식해 알아서 변속한다…기아 더 뉴 K9',
 'https://www.yna.co.kr/amp/view/AKR20210629181400003',
 date '2021-06-30','장하나','3.3T',
 'RJ 2세대 K9 부분변경 모델을 서울 워커힐~포천 왕복 약 90km 주행하며 전방예측변속·승차감·실내·ADAS를 평가한 독립 시승자료.'),

('기아','니로','SG2','연합뉴스',
 '[시승기] L당 20㎞ 뛰어난 연비에 주행감도 경쾌한 신형 니로',
 'https://www.yna.co.kr/view/AKR20220127214000003',
 date '2022-01-28','김보경','1.6 하이브리드',
 'SG2 2세대 니로 출시 시승에서 연비·주행감·공간·친환경 소재와 상품성을 평가한 독립 시승자료.'),

('기아','레이','TAM','뉴스핌',
 '[시승기] 보급형 전기차의 끝판왕...작지만 강한 레이 EV',
 'https://www.newspim.com/news/view/20231013000722',
 date '2023-10-15','정승원','레이 EV',
 'TAM 레이 EV를 서울·경기 도심과 고속도로에서 1박2일 약 100km 주행하며 주행거리·가속·안정성·공간을 평가한 독립 시승자료.')
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
