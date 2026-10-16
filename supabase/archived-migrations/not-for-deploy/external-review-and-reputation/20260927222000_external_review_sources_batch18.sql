begin;
with src(brand,model,generation_code,source_name,title,url,published_date,author_label,powertrain,summary) as (
values
('랜드로버','디스커버리','L462','탑라이더','[시승기] 뉴 디스커버리, 반값으로 즐기는 레인지로버','https://www.top-rider.com/article/view/trd202203230001',date '2022-03-23','이한승','P360 MHEV','L462 디스커버리 부분변경 실제 시승 평가 자료.'),
('랜드로버','레인지로버','L460','탑라이더','[시승기] 5세대 레인지로버, 온로드 주행성능이 달라졌다','https://www.top-rider.com/article/view/trd202208250001',date '2022-08-25','이한승','5세대 레인지로버','L460 5세대 레인지로버 실제 시승 평가 자료.'),
('랜드로버','레인지로버 이보크','L551','탑라이더','[시승기] 레인지로버 이보크, 디자인으로 가치는 충분','https://www.top-rider.com/article/view/trd202301100001',date '2023-01-10','이한승','2세대 이보크','L551 2세대 이보크 실제 시승 평가 자료.'),
('토요타','캠리','XV80','탑라이더','[시승기] 신형 캠리 2025년형, 완성도와 거주성 향상','https://www.top-rider.com/article/view/trd202412180002',date '2024-12-18','이한승','2.5 하이브리드','XV80 신형 캠리 실제 시승 평가 자료.'),
('포드','머스탱','S650','모터그래프','무서운 차 아니에요! 친숙함으로 무장한 포드 7세대 머스탱 5.0 GT [시승기]','https://www.motorgraph.com/news/articleView.html?idxno=41367',date '2024-12-09','김선웅','5.0 V8 GT','S650 7세대 머스탱 GT 실제 시승 평가 자료.'),
('포르쉐','마칸','2세대 EV','오토뷰','마세라티 그레칼레 폴고레 & 포르쉐 마칸 S 리뷰 [1241회]','https://www.autoview.co.kr/ko-kr/articles/98163',date '2025-11-29','오토뷰 로드테스트팀','마칸 4 EV','2세대 전기 마칸 전문 계측 비교 로드테스트.')
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
join public.generations g on g.car_model_id=cm.id and coalesce(g.generation_code,g.name)=s.generation_code
on conflict(canonical_url) do update set
 generation_id=excluded.generation_id,source_type='expert_road_test',source_name=excluded.source_name,
 title=excluded.title,published_date=excluded.published_date,observed_date=excluded.observed_date,
 author_label=excluded.author_label,powertrain_hint=excluded.powertrain_hint,summary=excluded.summary,
 source_confidence='A',approval_status='approved_reference',dedupe_status='unique',
 owner_score_eligible=false,value_score_eligible=false,updated_at=now();
commit;
