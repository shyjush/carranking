begin;
with src(brand,model,generation_code,source_name,title,url,published_date,author_label,powertrain,summary) as (
values
('BMW','7시리즈','G70','탑라이더','[시승기] BMW 신형 7시리즈, 파격적인 4세대를 닮았다','https://www.top-rider.com/article/view/trd202212210002',date '2022-12-21','이한승','740i sDrive','G70 7시리즈 740i 실제 시승 평가 자료.'),
('BMW','i5','G60','탑라이더','[시승기] BMW i5, 5시리즈 전기차 실주행거리 609km','https://www.top-rider.com/article/view/trd202311160001',date '2023-11-16','이한승','i5 eDrive40','G60 i5 실제 시승에서 효율·주행거리·승차감과 상품성을 평가한 자료.'),
('BMW','X1','U11','탑라이더','[시승기] BMW 뉴 X1 20i, 넓은 실내와 놀라운 자동주차','https://www.top-rider.com/article/view/trd202304110001',date '2023-04-11','이한승','sDrive20i','U11 3세대 X1 실제 시승 평가 자료.'),
('BMW','X3','G45','탑라이더','[시승기] BMW 신형 X3, 승차감 개선과 이상한 페달 위치','https://www.top-rider.com/article/view/trd202411290001',date '2024-11-29','이한승','X3 20 xDrive','G45 신형 X3 실제 시승 평가 자료.'),
('랜드로버','디펜더','L663','탑라이더','[시승기] 랜드로버 디펜더 옥타, 635마력 오프로드 스포츠카','https://www.top-rider.com/article/view/trd202508220001',date '2025-08-22','이한승','Defender OCTA 4.4 V8','L663 디펜더 현행 세대의 고성능 파생형 실제 온로드·오프로드 시승자료.'),
('아우디','A8','D5','탑라이더','[시승기] 아우디 A8L 60 TFSI, 주행성능과 승차감은 탑클래스','https://www.top-rider.com/article/view/trd202304120001',date '2023-04-12','이한승','A8L 60 TFSI','D5 A8 부분변경 실제 시승 평가 자료.'),
('아우디','Q7','4M','오토뷰','[시승기] 아우디, Q7 45 TFSI Quattro','https://www.autoview.co.kr/ko-kr/articles/69860',date '2020-02-14','오토뷰 로드테스트팀','Q7 45 TFSI quattro','4M Q7 전문 계측 시승자료.')
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
