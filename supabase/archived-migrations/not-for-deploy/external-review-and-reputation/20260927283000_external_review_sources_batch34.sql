begin;
with src(brand,model,generation_code,source_type,source_name,title,url,published_date,author_label,powertrain,summary,confidence) as (
values
('기아','K9','KH','expert_road_test','더아이오토','[시승기] 기아 2013 K9 3.8','https://www.theiauto.com/news/759',null,null,'3.8 GDi','KH 1세대 K9 실제 시승 평가 자료.','B'),
('포드','익스페디션','U553','expert_road_test','대한경제','[시승기] 車박 욕심나는 포드 익스페디션','https://www.dnews.co.kr/uhtml/view.jsp?idxno=202109241052377490573',date '2021-09-24',null,'3.5 EcoBoost','U553 익스페디션을 서울~홍천 왕복 약 170km 주행한 독립 시승자료.','B'),
('아우디','Q3','F3','expert_road_test','Car and Driver','2021 Audi Q3 Review, Pricing, and Specs','https://www.caranddriver.com/audi/q3-2021',null,'Drew Dorian','2.0T quattro','F3 2세대 Q3의 주행·공간·파워트레인을 평가한 독립 전문 리뷰.','B'),
('폭스바겐','티구안','AD1','expert_road_test','Car and Driver','Tested: 2018 Volkswagen Tiguan 4MOTION','https://www.caranddriver.com/reviews/a15083115/2018-volkswagen-tiguan-4motion-test-review/',date '2017-08-31','Greg S. Fink','2.0T 4MOTION','AD1 2세대 티구안의 가속·제동·주행을 직접 시험한 전문 테스트.','A'),
('테슬라','Model S','현행형','expert_road_test','Car and Driver','Tested: 2021 Tesla Model S Plaid','https://www.caranddriver.com/reviews/a38423992/2021-tesla-model-s-plaid-by-the-numbers/',date '2021-12-08','Dave VanderWerp','Plaid AWD','2021+ Model S Plaid의 가속·제동·스키드패드·고속도로 주행거리까지 직접 계측한 전문 테스트.','A'),
('테슬라','Model X','현행형','expert_road_test','Car and Driver','2022 Tesla Model X Review, Pricing, and Specs','https://www.caranddriver.com/tesla/model-x-2022',null,'Drew Dorian','Dual Motor / Plaid','2021+ Model X 세대의 파워트레인·주행·공간을 다룬 독립 전문 평가. 직접 계측 확정 범위가 제한돼 B로 분류.','B')
)
insert into public.external_review_sources(
 generation_id,source_type,source_name,title,canonical_url,published_date,observed_date,
 author_label,powertrain_hint,summary,source_confidence,approval_status,dedupe_status,
 owner_claimed,owner_verified,owner_score_eligible,value_score_eligible)
select g.id,s.source_type,s.source_name,s.title,s.url,s.published_date,date '2026-09-27',
 s.author_label,s.powertrain,s.summary,s.confidence,'approved_reference','unique',false,false,false,false
from src s
join public.manufacturers mf on mf.name=s.brand
join public.car_models cm on cm.manufacturer_id=mf.id and cm.name=s.model
join public.generations g on g.car_model_id=cm.id and coalesce(g.generation_code,g.name)=s.generation_code
on conflict(canonical_url) do update set
 generation_id=excluded.generation_id,source_type=excluded.source_type,source_name=excluded.source_name,
 title=excluded.title,published_date=excluded.published_date,observed_date=excluded.observed_date,
 author_label=excluded.author_label,powertrain_hint=excluded.powertrain_hint,summary=excluded.summary,
 source_confidence=excluded.source_confidence,approval_status='approved_reference',dedupe_status='unique',
 owner_score_eligible=false,value_score_eligible=false,updated_at=now();
commit;
