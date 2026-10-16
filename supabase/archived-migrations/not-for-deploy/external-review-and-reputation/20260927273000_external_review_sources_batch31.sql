begin;
with src(brand,model,generation_code,source_name,title,url,published_date,author_label,powertrain,summary) as (
values
('기아','K5','TF','오토뷰','[시승기] 기아 K5 2.4GDi','https://www.autoview.co.kr/ko-kr/articles/38185',date '2010-06-29','오토뷰 로드테스트팀','2.4 GDi','TF 1세대 K5 전문 계측 로드테스트.'),
('기아','모닝','SA','오토뷰','[시승기] 기아 모닝 vs GM대우 마티즈 크리에이티브','https://www.autoview.co.kr/ko-kr/articles/37079',date '2010-04-19','오토뷰 로드테스트팀','1.0 가솔린','SA 1세대 후기형 모닝을 동급 경차와 직접 비교한 전문 테스트.'),
('르노코리아','SM5','L43','오토뷰','[시승기] 르노삼성 뉴 SM5','https://www.autoview.co.kr/ko-kr/articles/35713',date '2010-02-08','오토뷰 로드테스트팀','2.0 가솔린 CVT','L43 3세대 SM5 전문 로드테스트.'),
('쉐보레','말리부','V300','오토뷰','[시승기] 쉐보레, 말리부 2.0','https://www.autoview.co.kr/ko-kr/articles/43737',date '2012-02-02','오토뷰 로드테스트팀','2.0 가솔린','V300 8세대 국내형 말리부 전문 계측 로드테스트.')
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
