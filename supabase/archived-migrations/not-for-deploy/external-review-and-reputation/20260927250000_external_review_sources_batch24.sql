begin;
with src(brand,model,generation_code,source_name,title,url,published_date,author_label,powertrain,summary) as (
values
('현대','그랜저','HG','오토뷰','[시승기] 현대, 그랜저 HG','https://www.autoview.co.kr/ko-kr/articles/40803',date '2011-03-28','오토뷰 로드테스트팀',null,'HG 그랜저 전문 로드테스트.'),
('현대','쏘나타','YF','오토뷰','[시승기] 현대 쏘나타 Y20','https://www.autoview.co.kr/ko-kr/articles/33934',null,'오토뷰 로드테스트팀',null,'YF 쏘나타 전문 로드테스트.'),
('현대','투싼','TL','오토뷰','[시승기] 현대, 투싼 e-VGT R2.0 2WD','https://www.autoview.co.kr/ko-kr/articles/59591',date '2016-09-12','오토뷰 로드테스트팀','2.0 디젤','TL 투싼 전문 계측 로드테스트.'),
('기아','K5','JF','오토뷰','[시승기] 기아 K5 2.0 CVVL','https://www.autoview.co.kr/ko-kr/articles/57576',date '2016-01-12','오토뷰 로드테스트팀','2.0 CVVL','JF 2세대 K5 전문 로드테스트.'),
('현대','코나','OS','오토뷰','[시승기] 현대, 코나 1.6 T-GDi 4WD','https://www.autoview.co.kr/ko-kr/articles/62390',date '2017-09-12','오토뷰 로드테스트팀','1.6T 4WD','OS 1세대 코나 전문 로드테스트.'),
('쉐보레','트랙스','U200','오토뷰','[시승기] 쉐보레, 트랙스 1.4 터보','https://www.autoview.co.kr/ko-kr/articles/47739',date '2013-03-22','오토뷰 로드테스트팀','1.4 터보','U200 트랙스 전문 로드테스트.'),
('쉐보레','말리부','E2XX','오토뷰','[시승기] 쉐보레 말리부 E-터보(1.35 터보)','https://www.autoview.co.kr/ko-kr/articles/66736',date '2019-01-23','오토뷰 로드테스트팀','1.35 터보','E2XX 9세대 말리부 전문 로드테스트.'),
('르노코리아','QM3','J87','오토뷰','[시승기] 르노삼성, QM3','https://www.autoview.co.kr/ko-kr/articles/50502',date '2013-12-07','오토뷰 로드테스트팀','1.5 dCi','J87 QM3 전문 시승자료.')
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
