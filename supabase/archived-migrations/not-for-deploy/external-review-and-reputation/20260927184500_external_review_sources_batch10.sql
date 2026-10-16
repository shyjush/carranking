begin;

with src(
  brand, model, generation_code, source_type, source_name, title, canonical_url,
  published_date, observed_date, author_label, powertrain_hint, trim_hint,
  summary, source_confidence, approval_status, dedupe_status,
  owner_claimed, owner_verified
) as (
  values
    ('볼보','XC60','SPA','expert_road_test','오토뷰',
     '볼보 XC60 B5 AWD 리뷰 [1221회]',
     'https://www.autoview.co.kr/ko-kr/articles/96928',
     date '2025-08-30',date '2026-09-27','오토뷰 로드테스트팀','2.0 MHEV AWD','B5/B6 계열',
     'SPA XC60 전문 계측 리뷰. 가속·제동·무게·정숙성·승차감과 인포테인먼트 및 주행 특성을 평가한다.',
     'A','approved_reference','unique',false,false),

    ('볼보','XC90','SPA','expert_road_test','오토뷰',
     '볼보 XC90 T8 AWD 리뷰 [1258회]',
     'https://www.autoview.co.kr/ko-kr/articles/99097',
     date '2026-02-12',date '2026-09-27','오토뷰 로드테스트팀','2.0 PHEV AWD','T8',
     'SPA XC90 T8 AWD 전문 계측 리뷰. 플러그인 하이브리드 성능·제동·정숙성·승차감과 패밀리 SUV 상품성을 평가한다.',
     'A','approved_reference','unique',false,false),

    ('토요타','RAV4','XA50','expert_road_test','오토뷰',
     '토요타 라브4 PHEV 리뷰 [1047회]',
     'https://www.autoview.co.kr/ko-kr/articles/90578',
     date '2024-02-28',date '2026-09-27','오토뷰 로드테스트팀','2.5 PHEV AWD',null,
     'XA50 RAV4 PHEV 전문 로드테스트. 2.5 가솔린과 전후륜 모터 조합의 성능·효율·승차감 평가 근거다.',
     'A','approved_reference','unique',false,false),

    ('토요타','시에나','XL40','expert_road_test','오토뷰',
     '2026 토요타 시에나 하이브리드 리뷰 [1275회]',
     'https://www.autoview.co.kr/ko-kr/articles/100303',
     date '2026-05-23',date '2026-09-27','오토뷰 로드테스트팀','2.5 하이브리드','2WD',
     'XL40 시에나 하이브리드 전문 계측 리뷰. 다인승 공간·승차감·연비·주행 안정성과 제동 성능을 평가한다.',
     'A','approved_reference','unique',false,false),

    ('토요타','프리우스','XW60','expert_road_test','오토뷰',
     '토요타 프리우스 하이브리드 AWD 리뷰 [1236회]',
     'https://www.autoview.co.kr/ko-kr/articles/97886',
     date '2025-11-12',date '2026-09-27','오토뷰 로드테스트팀','2.0 하이브리드 AWD',null,
     'XW60 프리우스 하이브리드 AWD 전문 계측 리뷰. 실주행 연비·핸들링·승차감과 AWD 안정성을 평가한다.',
     'A','approved_reference','unique',false,false),

    ('토요타','하이랜더','XU70','expert_road_test','오토뷰',
     '토요타 하이랜더 리뷰 [1074회]',
     'https://www.autoview.co.kr/ko-kr/articles/90533',
     date '2024-02-27',date '2026-09-27','오토뷰 로드테스트팀','2.5 하이브리드','플래티넘',
     'XU70 하이랜더 2.5 하이브리드 7인승 전문 로드테스트. 효율·공간·승차감과 패밀리 SUV 특성을 평가한다.',
     'A','approved_reference','unique',false,false),

    ('토요타','크라운','S235','expert_road_test','오토뷰',
     '토요타 크라운 크로스오버 리뷰 [1064회]',
     'https://www.autoview.co.kr/ko-kr/articles/90543',
     date '2024-02-27',date '2026-09-27','오토뷰 로드테스트팀','2.4 듀얼부스트 하이브리드','크로스오버',
     'S235 크라운 크로스오버 전문 로드테스트. 2.4 듀얼부스트 하이브리드의 주행 성능과 상품성을 평가한다.',
     'A','approved_reference','unique',false,false),

    ('포르쉐','카이엔','E3','expert_road_test','오토뷰',
     '포르쉐 카이엔 S E-하이브리드 쿠페 리뷰 [1177회]',
     'https://www.autoview.co.kr/ko-kr/articles/94240',
     date '2025-01-20',date '2026-09-27','오토뷰 로드테스트팀','PHEV','S E-하이브리드 쿠페',
     'E3 카이엔 S E-하이브리드 쿠페 전문 로드테스트. 현행 카이엔 세대의 고성능 PHEV 주행·상품성 근거다.',
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
