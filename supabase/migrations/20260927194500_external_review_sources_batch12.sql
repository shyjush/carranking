begin;
with src(brand,model,generation_code,title,url,published_date,powertrain,trim_name,summary) as (
values
('렉서스','NX','AZ20','렉서스 NX 350h 리뷰 [1249회]','https://www.autoview.co.kr/ko-kr/articles/98640',date '2026-01-10','2.5 하이브리드 AWD','NX350h','AZ20 NX350h 전문 계측 로드테스트.'),
('볼보','XC40','CMA','볼보 XC40 B4 AWD 리뷰 [1211회]','https://www.autoview.co.kr/ko-kr/articles/96202',date '2025-07-01','2.0 MHEV AWD','B4 Ultra','CMA XC40 전문 로드테스트.'),
('볼보','S90','SPA','볼보 S90 T8 AWD 리뷰 [1253회]','https://www.autoview.co.kr/ko-kr/articles/98855',date '2026-01-24','2.0 PHEV AWD','T8','SPA S90 전문 계측 로드테스트.')
)
insert into public.external_review_sources(
 generation_id,source_type,source_name,title,canonical_url,published_date,observed_date,
 author_label,powertrain_hint,trim_hint,summary,source_confidence,approval_status,dedupe_status,
 owner_claimed,owner_verified,owner_score_eligible,value_score_eligible)
select g.id,'expert_road_test','오토뷰',s.title,s.url,s.published_date,date '2026-09-27',
 '오토뷰 로드테스트팀',s.powertrain,s.trim_name,s.summary,'A','approved_reference','unique',
 false,false,false,false
from src s
join public.manufacturers mf on mf.name=s.brand
join public.car_models cm on cm.manufacturer_id=mf.id and cm.name=s.model
join public.generations g on g.car_model_id=cm.id and g.generation_code=s.generation_code
on conflict(canonical_url) do update set
 generation_id=excluded.generation_id,title=excluded.title,published_date=excluded.published_date,
 observed_date=excluded.observed_date,powertrain_hint=excluded.powertrain_hint,trim_hint=excluded.trim_hint,
 summary=excluded.summary,source_confidence='A',approval_status='approved_reference',
 owner_score_eligible=false,value_score_eligible=false,updated_at=now();
commit;
