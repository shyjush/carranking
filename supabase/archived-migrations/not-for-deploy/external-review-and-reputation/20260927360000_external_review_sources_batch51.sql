begin;

with src(brand,model,generation_code,source_name,title,url,published_date,author_label,powertrain,summary) as (
values
('볼보','XC60','SPA','뉴스핌',
 '[시승기] 이유 있는 베스트셀링 SUV…볼보 XC60, 완성형에 가까운 편안함',
 'https://www.newspim.com/news/view/20250807001094',
 date '2025-08-08','조수빈','XC60 B5 Ultra',
 'SPA XC60 신형을 서울 도심~용인 왕복 약 80km 주행하며 에어서스펜션·승차감·정숙성·인포테인먼트와 공간을 평가한 독립 시승자료.'),

('볼보','XC90','SPA','연합뉴스',
 '[시승기] 6년 만에 돌아온 볼보 XC90…인포테인먼트·승차감 개선',
 'https://www.yna.co.kr/amp/view/AKR20250710094100003',
 date '2025-07-11','홍규빈','XC90 B6',
 'SPA XC90 부분변경 국내 시승에서 승차감·인포테인먼트·2·3열 공간과 패밀리 SUV 활용성을 평가한 독립 시승자료.'),

('렉서스','ES','XV70','탑라이더',
 '[시승기] 렉서스 ES300h 2026년형, 한국에서 10만대 팔린 이유',
 'https://www.top-rider.com/article/view/trd202508270001',
 date '2025-08-27','이한승','ES300h 2026 Executive',
 'XV70 ES300h 2026년형을 실제 시승해 고급감·승차감·고속안정성·하이브리드 효율과 장기 가치 관점을 평가한 독립 전문 시승자료.')
)
insert into public.external_review_sources(
 generation_id,source_type,source_name,title,canonical_url,published_date,observed_date,
 author_label,powertrain_hint,summary,source_confidence,approval_status,dedupe_status,
 owner_claimed,owner_verified,owner_score_eligible,value_score_eligible)
select g.id,'expert_road_test',s.source_name,s.title,s.url,s.published_date,date '2026-09-27',
 s.author_label,s.powertrain,s.summary,'B','approved_reference','unique',false,false,false,false
from src s
join public.manufacturers mf on mf.name=s.brand
join public.car_models cm on cm.manufacturer_id=mf.id and cm.name=s.model
join public.generations g on g.car_model_id=cm.id and g.generation_code=s.generation_code
on conflict(canonical_url) do update set
 generation_id=excluded.generation_id,
 source_type='expert_road_test',
 source_name=excluded.source_name,
 title=excluded.title,
 published_date=excluded.published_date,
 observed_date=excluded.observed_date,
 author_label=excluded.author_label,
 powertrain_hint=excluded.powertrain_hint,
 summary=excluded.summary,
 source_confidence='B',
 approval_status='approved_reference',
 dedupe_status='unique',
 owner_score_eligible=false,
 value_score_eligible=false,
 updated_at=now();

commit;
