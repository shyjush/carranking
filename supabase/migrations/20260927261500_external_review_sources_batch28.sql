begin;
with src(brand,model,generation_code,source_name,title,url,published_date,author_label,powertrain,summary) as (
values
('기아','쏘렌토','UM','오토뷰','[시승기] 기아, 쏘렌토 R2.2 2WD 프레스티지','https://www.autoview.co.kr/ko-kr/articles/55446',date '2015-05-04','오토뷰 로드테스트팀','2.2 디젤','UM 3세대 쏘렌토 전문 로드테스트.'),
('현대','싼타페','TM','오토뷰','[시승기] 현대, 싼타페 R2.2 e-VGT 4WD','https://www.autoview.co.kr/ko-kr/articles/64071',date '2018-04-03','오토뷰 로드테스트팀','2.2 디젤 4WD','TM 4세대 싼타페 전문 로드테스트.'),
('현대','싼타페','DM','오토뷰','[시승기] 현대, 싼타페 R2.0 4WD','https://www.autoview.co.kr/ko-kr/articles/48579',date '2013-05-31','오토뷰 로드테스트팀','2.0 디젤 4WD','DM 3세대 싼타페 전문 로드테스트.'),
('현대','팰리세이드','LX2','오토뷰','[시승기] 현대, 팰리세이드 3.8 HTRAC','https://www.autoview.co.kr/ko-kr/articles/66834',date '2019-02-05','오토뷰 로드테스트팀','3.8 HTRAC','LX2 1세대 팰리세이드 전문 계측 로드테스트.'),
('르노코리아','SM6','LFD','오토뷰','[시승기] 르노삼성, SM6 2.0 GDe','https://www.autoview.co.kr/ko-kr/articles/58585',date '2016-05-11','오토뷰 로드테스트팀','2.0 GDe','LFD SM6 전문 로드테스트.'),
('쉐보레','크루즈','J300','오토뷰','[시승기] 쉐보레, 크루즈5 1.8','https://www.autoview.co.kr/ko-kr/articles/41922',date '2011-07-22','오토뷰 로드테스트팀','1.8 가솔린','J300 크루즈 계열 전문 로드테스트.'),
('KGM','코란도','C200','오토뷰','[시승기] 쌍용, 뉴 스타일 코란도 C','https://www.autoview.co.kr/ko-kr/articles/60888',null,'오토뷰 로드테스트팀','2.2 디젤','C200 코란도 C 전문 계측 로드테스트.')
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
