begin;
with src(brand,model,generation_code,title,url,published_date,author_label,powertrain,summary) as (
values
('현대','아반떼','MD','[시승기] 현대 아반떼 1.6 GDi','https://www.autoview.co.kr/ko-kr/articles/39370',date '2010-10-04','오토뷰 로드테스트팀','1.6 GDi','MD 아반떼의 가속·고속안정성·핸들링을 직접 계측한 전문 로드테스트.'),
('르노코리아','SM3','L38','[시승기] 르노삼성, SM3 1.6','https://www.autoview.co.kr/ko-kr/articles/39770',date '2010-11-16','오토뷰 로드테스트팀','1.6 CVT','L38 2세대 SM3의 가속·정숙성·제동·주행 특성을 계측한 전문 로드테스트.')
)
insert into public.external_review_sources(
 generation_id,source_type,source_name,title,canonical_url,published_date,observed_date,
 author_label,powertrain_hint,summary,source_confidence,approval_status,dedupe_status,
 owner_claimed,owner_verified,owner_score_eligible,value_score_eligible)
select g.id,'expert_road_test','오토뷰',s.title,s.url,s.published_date,date '2026-09-27',
 s.author_label,s.powertrain,s.summary,'A','approved_reference','unique',false,false,false,false
from src s
join public.manufacturers mf on mf.name=s.brand
join public.car_models cm on cm.manufacturer_id=mf.id and cm.name=s.model
join public.generations g on g.car_model_id=cm.id and g.generation_code=s.generation_code
on conflict(canonical_url) do update set
 generation_id=excluded.generation_id,source_type='expert_road_test',source_name='오토뷰',
 title=excluded.title,published_date=excluded.published_date,observed_date=excluded.observed_date,
 author_label=excluded.author_label,powertrain_hint=excluded.powertrain_hint,summary=excluded.summary,
 source_confidence='A',approval_status='approved_reference',dedupe_status='unique',
 owner_score_eligible=false,value_score_eligible=false,updated_at=now();
commit;
