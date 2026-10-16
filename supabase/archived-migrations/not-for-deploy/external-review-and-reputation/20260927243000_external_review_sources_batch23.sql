begin;
with src(brand,model,generation_code,source_name,title,url,published_date,author_label,powertrain,summary) as (
values
('현대','그랜저','IG','오토뷰','[시승기] 현대, 그랜저 IG 3.0','https://www.autoview.co.kr/ko-kr/articles/60695',date '2017-02-08','오토뷰 로드테스트팀','3.0 GDi','IG 그랜저 전문 계측 시승자료.'),
('현대','아반떼','AD','오토뷰','[시승기] 현대 아반떼 1.6 GDi (AD)','https://www.autoview.co.kr/ko-kr/articles/57183',date '2015-11-23','오토뷰 로드테스트팀','1.6 GDi','AD 아반떼 전문 계측 시승자료.'),
('현대','쏘나타','LF','오토뷰','[시승기] 현대, 쏘나타 2.0 CVVL','https://www.autoview.co.kr/ko-kr/articles/52650',date '2014-07-17','오토뷰 로드테스트팀','2.0 CVVL','LF 쏘나타 전문 계측 시승자료.'),
('제네시스','G80','DH','오토뷰','[시승기] 제네시스, G80 2.2d HTRAC','https://www.autoview.co.kr/ko-kr/articles/65230',date '2018-08-06','오토뷰 로드테스트팀','2.2 디젤 HTRAC','DH G80 전문 계측 시승자료.')
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
