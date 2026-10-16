begin;
with src(brand,model,generation_code,source_name,title,url,published_date,author_label,powertrain,summary) as (
values
('기아','K3','YD','오토뷰','[시승기] 기아, K3 1.6 GDI','https://www.autoview.co.kr/ko-kr/articles/46769',date '2012-12-19','오토뷰 로드테스트팀','1.6 GDI','YD 1세대 K3 전문 로드테스트.'),
('기아','모하비','HM','오토뷰','[시승기] 기아, 모하비 3.0 디젤 4WD (5인승)','https://www.autoview.co.kr/ko-kr/articles/68877',date '2019-09-28','오토뷰 로드테스트팀','3.0 디젤 4WD','HM 모하비 전문 계측 로드테스트.'),
('쉐보레','스파크','M400','오토뷰','[시승기] 기아 모닝 & 쉐보레 스파크','https://www.autoview.co.kr/ko-kr/articles/61408',date '2017-05-02','오토뷰 로드테스트팀','1.0 가솔린','M400 스파크를 동급 모닝과 동일 조건에서 비교 계측한 전문 자료.')
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
