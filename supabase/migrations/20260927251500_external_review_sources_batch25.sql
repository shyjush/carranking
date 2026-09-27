begin;

update public.external_review_sources
set approval_status='hold',
    source_confidence='C',
    summary='원문 자체가 삭제된 것은 아니나 자동 URL 감사에서 HTTP 403이 지속되어 공개 승인 근거에서 제외. 대체 독립 시승근거로 교체.',
    updated_at=now()
where canonical_url='https://www.edmunds.com/ford/expedition/2025/';

insert into public.external_review_sources(
 generation_id,source_type,source_name,title,canonical_url,published_date,observed_date,
 author_label,powertrain_hint,summary,source_confidence,approval_status,dedupe_status,
 owner_claimed,owner_verified,owner_score_eligible,value_score_eligible)
select g.id,'expert_road_test','Car and Driver',
 'Tested: 2025 Ford Expedition Test: Just Shy of Greatness',
 'https://www.caranddriver.com/reviews/a65103388/2025-ford-expedition-test/',
 date '2025-06-25',date '2026-09-27','Andrew Krok','3.5L twin-turbo V6',
 '5세대 2025 Expedition의 가속·연비·제동·스키드패드·승차감까지 직접 계측한 독립 전문 테스트.',
 'A','approved_reference','unique',false,false,false,false
from public.generations g
join public.car_models cm on cm.id=g.car_model_id
join public.manufacturers mf on mf.id=cm.manufacturer_id
where mf.name='포드' and cm.name='익스페디션' and g.name='5세대'
on conflict(canonical_url) do update set
 generation_id=excluded.generation_id,source_type=excluded.source_type,source_name=excluded.source_name,
 title=excluded.title,published_date=excluded.published_date,observed_date=excluded.observed_date,
 author_label=excluded.author_label,powertrain_hint=excluded.powertrain_hint,summary=excluded.summary,
 source_confidence='A',approval_status='approved_reference',dedupe_status='unique',
 owner_score_eligible=false,value_score_eligible=false,updated_at=now();

commit;
