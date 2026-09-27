begin;
with src(brand,model,generation_code,source_name,title,url,published_date,author_label,powertrain,summary,confidence) as (
values
('BMW','5시리즈','G30','오토뷰','[시승기] BMW, 520d (럭셔리 라인)','https://www.autoview.co.kr/ko-kr/articles/65797',null,'오토뷰 로드테스트팀','520d','G30 5시리즈 520d 전문 계측 로드테스트.','A'),
('렉서스','RX','AL20','오토뷰','[시승기] 렉서스 RX350 & RX450h','https://www.autoview.co.kr/ko-kr/articles/58395',null,'오토뷰 로드테스트팀','RX350 / RX450h','AL20 4세대 RX 전문 계측 로드테스트.','A'),
('테슬라','Model 3','MODEL3-1','오토뷰','[시승기] 테슬라, 모델 3 퍼포먼스','https://www.autoview.co.kr/ko-kr/articles/71527',null,'오토뷰 로드테스트팀','Performance AWD','2019~2023 Model 3 전문 계측 로드테스트.','A'),
('테슬라','Model Y','MODELY-1','Cars.com','2021 Tesla Model Y Review: Have Your Cake and Eat It, Too','https://www.cars.com/articles/2021-tesla-model-y-review-have-your-cake-and-eat-it-too-437232/',date '2021-06-30','Joe Bruzek','Long Range AWD','2021 Model Y 장기 직접 주행 기반 독립 전문 리뷰.','A')
)
insert into public.external_review_sources(
 generation_id,source_type,source_name,title,canonical_url,published_date,observed_date,
 author_label,powertrain_hint,summary,source_confidence,approval_status,dedupe_status,
 owner_claimed,owner_verified,owner_score_eligible,value_score_eligible)
select g.id,'expert_road_test',s.source_name,s.title,s.url,s.published_date,date '2026-09-27',
 s.author_label,s.powertrain,s.summary,s.confidence,'approved_reference','unique',false,false,false,false
from src s
join public.manufacturers mf on mf.name=s.brand
join public.car_models cm on cm.manufacturer_id=mf.id and cm.name=s.model
join public.generations g on g.car_model_id=cm.id and coalesce(g.generation_code,g.name)=s.generation_code
on conflict(canonical_url) do update set
 generation_id=excluded.generation_id,source_type='expert_road_test',source_name=excluded.source_name,
 title=excluded.title,published_date=excluded.published_date,observed_date=excluded.observed_date,
 author_label=excluded.author_label,powertrain_hint=excluded.powertrain_hint,summary=excluded.summary,
 source_confidence=excluded.source_confidence,approval_status='approved_reference',dedupe_status='unique',
 owner_score_eligible=false,value_score_eligible=false,updated_at=now();
commit;
