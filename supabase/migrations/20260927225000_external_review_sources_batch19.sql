begin;
with src(brand,model,generation_code,source_name,title,url,published_date,author_label,powertrain,summary) as (
values
('MINI','에이스맨','J05','탑라이더','[시승기] 미니 에이스맨, 너무 커진 컨트리맨이 부담스럽다면','https://www.top-rider.com/article/view/trd202503130005',date '2025-03-13','이한승','전기','J05 에이스맨 실제 시승 평가 자료.'),
('MINI','컨트리맨','U25','탑라이더','[시승기] 뉴 미니 컨트리맨, 대중성까지 노린 패밀리카','https://www.top-rider.com/article/view/trd202406140001',date '2024-06-14','이한승','2.0T ALL4','U25 신형 컨트리맨 실제 시승 평가 자료.'),
('MINI','쿠퍼','F66','탑라이더','[시승기] 뉴 미니 쿠퍼S, 가벼운 핸들링과 개선된 승차감','https://www.top-rider.com/article/view/trd202407080001',date '2024-07-08','이한승','2.0T Cooper S','F66 4세대 내연기관 미니 쿠퍼 S 실제 시승 평가 자료.'),
('BMW','X5','G05','탑라이더','[시승기] BMW X5 하이브리드, 연비 20km/L가 어려운가?','https://www.top-rider.com/article/view/trd202409240003',date '2024-09-24','김한솔','X5 xDrive50e PHEV','G05 X5 부분변경 PHEV 실제 시승 평가 자료.'),
('BMW','X6','G06','탑라이더','[시승기] BMW X6 부분변경 M60i, 쿠페형 SUV 모범답안','https://www.top-rider.com/article/view/trd202309070002',date '2023-09-07','김한솔','X6 M60i xDrive','G06 X6 부분변경 실제 시승 평가 자료.')
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
