begin;

update public.external_review_sources
set approval_status='hold',
    source_confidence='C',
    summary='자동 URL 감사에서 HTTP 403이 지속되어 공개 승인 근거에서 제외. 동일 세대의 대체 독립 테스트 원문으로 교체.',
    updated_at=now()
where canonical_url='https://www.cars.com/articles/2021-tesla-model-y-review-have-your-cake-and-eat-it-too-437232/';

insert into public.external_review_sources(
 generation_id,source_type,source_name,title,canonical_url,published_date,observed_date,
 author_label,powertrain_hint,summary,source_confidence,approval_status,dedupe_status,
 owner_claimed,owner_verified,owner_score_eligible,value_score_eligible)
select g.id,'expert_road_test','Car and Driver',
 '2021 Tesla Model Y Review, Pricing, and Specs',
 'https://www.caranddriver.com/tesla/model-y-2021',
 null,date '2026-09-27','Car and Driver','2021 Model Y',
 '2021 Model Y 세대의 가속·고속도로 효율·제동 및 주행 특성을 직접 시험한 독립 전문 테스트 페이지.',
 'A','approved_reference','unique',false,false,false,false
from public.generations g
join public.car_models cm on cm.id=g.car_model_id
join public.manufacturers mf on mf.id=cm.manufacturer_id
where mf.name='테슬라' and cm.name='Model Y' and g.generation_code='MODELY-1'
on conflict(canonical_url) do update set
 generation_id=excluded.generation_id,source_type=excluded.source_type,source_name=excluded.source_name,
 title=excluded.title,observed_date=excluded.observed_date,author_label=excluded.author_label,
 powertrain_hint=excluded.powertrain_hint,summary=excluded.summary,
 source_confidence='A',approval_status='approved_reference',dedupe_status='unique',
 owner_score_eligible=false,value_score_eligible=false,updated_at=now();

commit;
