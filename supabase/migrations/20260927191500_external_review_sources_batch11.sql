begin;

with src(
  brand, model, generation_code, source_type, source_name, title, canonical_url,
  published_date, observed_date, author_label, powertrain_hint, trim_hint,
  summary, source_confidence, approval_status, dedupe_status,
  owner_claimed, owner_verified
) as (
  values
    ('BMW','i4','G26','expert_road_test','오토뷰',
     '[시승기] 2024 BMW i4 M50',
     'https://www.autoview.co.kr/ko-kr/articles/90642',
     date '2024-03-05',date '2026-09-27','전인호 기자','전기 AWD','i4 M50',
     'G26 i4 M50 실제 시승기. 전기 그란쿠페의 섀시 밸런스·주행 성능과 일상 주행 특성을 평가한다.',
     'A','approved_reference','unique',false,false),

    ('포드','익스플로러','7세대','expert_road_test','오토뷰',
     '2026 포드 익스플로러 리뷰 [1274회]',
     'https://www.autoview.co.kr/ko-kr/articles/100195',
     date '2026-05-16',date '2026-09-27','오토뷰 로드테스트팀','3.0 에코부스트 AWD','Tremor',
     '현행 익스플로러 전문 계측 리뷰. 가속·제동·정숙성·온로드/오프로드 주행 및 상품성을 평가한다.',
     'A','approved_reference','unique',false,false),

    ('포르쉐','911','992','expert_road_test','오토뷰',
     '포르쉐 911 카레라 4 GTS 리뷰 [1216회]',
     'https://www.autoview.co.kr/ko-kr/articles/96597',
     date '2025-07-31',date '2026-09-27','오토뷰 로드테스트팀','3.6 하이브리드 AWD','Carrera 4 GTS',
     '992 세대 911 카레라 4 GTS 전문 계측 리뷰. 가속·제동·섀시 밸런스·정숙성과 고성능 주행 특성을 평가한다.',
     'A','approved_reference','unique',false,false),

    ('포르쉐','타이칸','J1','expert_road_test','오토뷰',
     '포르쉐 타이칸 GTS 리뷰 [1199회]',
     'https://www.autoview.co.kr/ko-kr/articles/95550',
     date '2025-05-08',date '2026-09-27','오토뷰 로드테스트팀','전기 AWD','GTS',
     'J1 타이칸 GTS 전문 로드테스트. 현행 타이칸 세대의 고성능 전기차 주행 특성을 평가한다.',
     'A','approved_reference','unique',false,false),

    ('폭스바겐','ID.4','E21','expert_road_test','오토뷰',
     '폭스바겐 ID.5 & 25년형 ID.4 리뷰 [1178회]',
     'https://www.autoview.co.kr/ko-kr/articles/94270',
     date '2025-01-23',date '2026-09-27','오토뷰 로드테스트팀','전기', '2025 ID.4',
     'E21 ID.4 2025년형과 ID.5를 함께 다룬 전문 로드테스트. ID.4 현행 세대의 주행·상품성 참고 근거다.',
     'A','approved_reference','unique',false,false)
)
insert into public.external_review_sources(
  generation_id, source_type, source_name, title, canonical_url,
  published_date, observed_date, author_label, powertrain_hint, trim_hint,
  summary, source_confidence, approval_status, dedupe_status,
  owner_claimed, owner_verified, owner_score_eligible, value_score_eligible
)
select
  g.id, s.source_type, s.source_name, s.title, s.canonical_url,
  s.published_date, s.observed_date, s.author_label, s.powertrain_hint, s.trim_hint,
  s.summary, s.source_confidence, s.approval_status, s.dedupe_status,
  s.owner_claimed, s.owner_verified, false, false
from src s
join public.manufacturers mf on mf.name=s.brand
join public.car_models cm on cm.manufacturer_id=mf.id and cm.name=s.model
join public.generations g on g.car_model_id=cm.id and g.generation_code=s.generation_code
on conflict (canonical_url) do update set
  generation_id=excluded.generation_id,
  source_type=excluded.source_type,
  source_name=excluded.source_name,
  title=excluded.title,
  published_date=excluded.published_date,
  observed_date=excluded.observed_date,
  author_label=excluded.author_label,
  powertrain_hint=excluded.powertrain_hint,
  trim_hint=excluded.trim_hint,
  summary=excluded.summary,
  source_confidence=excluded.source_confidence,
  approval_status=excluded.approval_status,
  dedupe_status=excluded.dedupe_status,
  owner_claimed=excluded.owner_claimed,
  owner_verified=excluded.owner_verified,
  owner_score_eligible=false,
  value_score_eligible=false,
  updated_at=now();

commit;
