begin;

with src(brand,model,generation_code,source_name,title,url,published_date,author_label,powertrain,summary) as (
values
('기아','PV5 WAV','PV5-WAV','오토헤럴드',
 '[시승기] 기아 PV5 오픈베드와 WAV 싣고 태우고, 슬기로운 활용법',
 'https://auto.danawa.com/news/?NewsGroup=M&Work=detail&no=5994126',
 date '2026-04-06','김흥식','PV5 WAV 롱레인지',
 'PV5 WAV를 실제 체험하며 측면 승하차, 인플로어 슬로프, 휠체어 고정력과 2열 이동 편의를 확인한 전용 시승·체험 자료.')
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
 generation_id=excluded.generation_id,source_type='expert_road_test',source_name=excluded.source_name,
 title=excluded.title,published_date=excluded.published_date,observed_date=excluded.observed_date,
 author_label=excluded.author_label,powertrain_hint=excluded.powertrain_hint,summary=excluded.summary,
 source_confidence='B',approval_status='approved_reference',dedupe_status='unique',
 owner_score_eligible=false,value_score_eligible=false,updated_at=now();

commit;
