begin;
with src(brand,model,generation_code,source_name,title,url,published_date,author_label,powertrain,summary) as (
values
('렉서스','LM','AW10','탑라이더','[시승기] 렉서스 LM500h 4인승, 신개념 쇼퍼드리븐 MPV','https://www.top-rider.com/article/view/trd202407260001',date '2024-07-26','이한승','LM500h 하이브리드','AW10 LM500h 실제 시승 평가 자료.'),
('렉서스','UX','ZA10','탑라이더','[시승기] 렉서스 UX 300e, 승차감 좋은 가성비 전기차','https://www.top-rider.com/article/view/trd202207060001',date '2022-07-06','이한승','UX300e','ZA10 UX 전기 파워트레인 실제 시승 평가 자료.'),
('메르세데스-벤츠','EQE','V295','탑라이더','[시승기] 벤츠 EQE 350+, 전기차 셋업 발전의 전환점','https://www.top-rider.com/article/view/trd202210130001',date '2022-10-13','이한승','EQE 350+','V295 EQE 실제 시승 평가 자료.'),
('랜드로버','레인지로버 벨라','L560','탑라이더','[시승기] 레인지로버 벨라 2025년형, 디자인 완성도는 최상급','https://www.top-rider.com/article/view/trd202408190001',date '2024-08-19','이한승','P400','L560 벨라 2025년형 실제 시승 평가 자료.')
)
insert into public.external_review_sources(
 generation_id,source_type,source_name,title,canonical_url,published_date,observed_date,
 author_label,powertrain_hint,summary,source_confidence,approval_status,dedupe_status,
 owner_claimed,owner_verified,owner_score_eligible,value_score_eligible)
select g.id,'expert_road_test',s.source_name,s.title,s.url,s.published_date,date '2026-09-27',
 s.author_label,s.powertrain,s.summary,'A','approved_reference','unique',false,false,false,false
from src s
join public.manufacturers mf on mf.name=s.brand
join public.car_models cm on cm.manufacturer_id=mf.id and cm.name=s.model
join public.generations g on g.car_model_id=cm.id and g.generation_code=s.generation_code
on conflict(canonical_url) do update set
 generation_id=excluded.generation_id,source_type='expert_road_test',source_name=excluded.source_name,
 title=excluded.title,published_date=excluded.published_date,observed_date=excluded.observed_date,
 author_label=excluded.author_label,powertrain_hint=excluded.powertrain_hint,summary=excluded.summary,
 source_confidence='A',approval_status='approved_reference',dedupe_status='unique',
 owner_score_eligible=false,value_score_eligible=false,updated_at=now();
commit;
