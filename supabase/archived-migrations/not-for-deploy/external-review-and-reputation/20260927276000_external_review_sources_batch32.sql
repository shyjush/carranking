begin;
with src(brand,model,generation_code,source_type,source_name,title,url,published_date,author_label,powertrain,summary,confidence) as (
values
('현대','투싼','LM','expert_road_test','오토뷰','[시승기] 현대 투싼 ix','https://www.autoview.co.kr/ko-kr/articles/34206',date '2009-11-26','오토뷰 로드테스트팀','2.0 e-VGT 디젤','LM 2세대 투싼 ix 전문 계측 로드테스트.','A'),
('현대','넥쏘','FE','expert_road_test','탑라이더','[시승기] 먼저 타본 미래차, 수소전기차 넥쏘','https://www.top-rider.com/article/view/trd201802060005',date '2018-02-06','이한승','수소전기','FE 넥쏘를 고양~평창 약 250km 구간에서 직접 주행한 전문 시승자료.','A'),
('현대','아반떼','MD','expert_road_test','국제신문','[현대車 아반떼MD 시승기] 중형같은 준중형','https://www.kookje.co.kr/news2011/asp/newsbody.asp?code=0200&key=20101004.22013210538',date '2010-10-03','방종근','1.6 가솔린','MD 아반떼 출시 초기 실제 시승 평가 자료. 전문 계측자료는 아니므로 B.','B')
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
join public.generations g on g.car_model_id=cm.id and g.generation_code=s.generation_code
on conflict(canonical_url) do update set
 generation_id=excluded.generation_id,source_type=excluded.source_type,source_name=excluded.source_name,
 title=excluded.title,published_date=excluded.published_date,observed_date=excluded.observed_date,
 author_label=excluded.author_label,powertrain_hint=excluded.powertrain_hint,summary=excluded.summary,
 source_confidence=excluded.source_confidence,approval_status='approved_reference',dedupe_status='unique',
 owner_score_eligible=false,value_score_eligible=false,updated_at=now();
commit;
