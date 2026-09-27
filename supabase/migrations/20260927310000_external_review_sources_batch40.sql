begin;

update public.external_review_sources
set approval_status='hold',
    source_confidence='C',
    summary='실제 원문은 존재하지만 자동 URL 감사에서 HTTP 403을 반환해 공개 승인 근거에서는 제외. 동일 JA 세대의 안정적인 대체 시승 원문을 등록.',
    updated_at=now()
where canonical_url='https://www.hankyung.com/article/201702081151g';

insert into public.external_review_sources(
 generation_id,source_type,source_name,title,canonical_url,published_date,observed_date,
 author_label,powertrain_hint,summary,source_confidence,approval_status,dedupe_status,
 owner_claimed,owner_verified,owner_score_eligible,value_score_eligible)
select
 g.id,'expert_road_test','이데일리 오토in',
 '[시승기] 기아 올 뉴 모닝 vs 쉐보레 더 뉴 스파크',
 'https://www.edaily.co.kr/News/Read?mediaCodeNo=257&newsId=01430086616094888',
 date '2017-10-20',date '2026-09-27',
 '김학수','올 뉴 모닝 JA 1.0 가솔린',
 'JA 올 뉴 모닝과 M400 스파크를 일상도로·와인딩·고갯길에서 직접 비교 시승하며 하체 움직임, 가속 반응, 조향과 주행 안정성을 평가한 독립 자료.',
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
