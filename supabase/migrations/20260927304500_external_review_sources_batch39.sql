begin;

insert into public.external_review_sources(
 generation_id,source_type,source_name,title,canonical_url,published_date,observed_date,
 author_label,powertrain_hint,summary,source_confidence,approval_status,dedupe_status,
 owner_claimed,owner_verified,owner_score_eligible,value_score_eligible)
select
 g.id,'expert_road_test','한국경제',
 '올 뉴 모닝, 인상적인 주행성능…경차 맞아?',
 'https://www.hankyung.com/article/201702081151g',
 date '2017-02-08',date '2026-09-27',
 '박상재','1.0 가솔린 프레스티지',
 'JA 3세대 올 뉴 모닝을 서울 워커힐~가평 약 100km 구간에서 직접 운전해 고속 코너링·주행 안정성·연비와 승차감을 평가한 독립 시승자료.',
 'B','approved_reference','unique',false,false,false,false
from public.generations g
join public.car_models cm on cm.id=g.car_model_id
join public.manufacturers mf on mf.id=cm.manufacturer_id
where mf.name='기아' and cm.name='모닝' and g.generation_code='JA'
on conflict(canonical_url) do update set
 generation_id=excluded.generation_id,
 source_type=excluded.source_type,
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
