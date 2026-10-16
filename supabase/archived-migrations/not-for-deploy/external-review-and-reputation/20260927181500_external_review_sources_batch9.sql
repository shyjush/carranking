begin;

with src(
  brand, model, generation_code, source_type, source_name, title, canonical_url,
  published_date, observed_date, author_label, powertrain_hint, trim_hint,
  summary, source_confidence, approval_status, dedupe_status,
  owner_claimed, owner_verified
) as (
  values
    ('BMW','3시리즈','G20','expert_road_test','오토뷰',
     '[시승기] BMW, 320i (G20 LCI)',
     'https://www.autoview.co.kr/ko-kr/articles/80093',
     date '2023-05-04',date '2026-09-27','오토뷰 로드테스트팀','2.0T 가솔린','320i LCI',
     'G20 LCI 320i를 장기간 실제 주행하며 조향·승차감·파워트레인·상품성을 평가한 전문 시승자료다.',
     'A','approved_reference','unique',false,false),

    ('BMW','5시리즈','G60','expert_road_test','오토뷰',
     'BMW 520i MSP 리뷰 [1235회]',
     'https://www.autoview.co.kr/ko-kr/articles/97791',
     date '2025-11-06',date '2026-09-27','오토뷰 로드테스트팀','2.0T 48V MHEV','520i M Sport',
     'G60 520i M Sport 전문 계측 리뷰. 가속·제동·중량·정숙성·가격과 승차감 및 조종성을 다룬다.',
     'A','approved_reference','unique',false,false),

    ('렉서스','ES','XV70','expert_road_test','오토뷰',
     '렉서스 ES300h 2026년형 리뷰 [1239회]',
     'https://www.autoview.co.kr/ko-kr/articles/98030',
     date '2025-11-20',date '2026-09-27','오토뷰 로드테스트팀','2.5 하이브리드','ES300h',
     'XV70 ES300h 2026년형 전문 계측 리뷰. 연비·가속·제동·정숙성·섀시와 장기보유 관점의 상품성을 평가한다.',
     'A','approved_reference','unique',false,false),

    ('렉서스','RX','ALA10','expert_road_test','오토뷰',
     '렉서스 RX350h [1152회]',
     'https://www.autoview.co.kr/ko-kr/articles/92864',
     date '2024-09-23',date '2026-09-27','오토뷰 로드테스트팀','2.5 하이브리드','RX350h',
     'ALA10 RX350h 전문 로드테스트 원문. 현행 RX 하이브리드의 주행·승차감·정숙성과 상품성 평가 근거다.',
     'A','approved_reference','unique',false,false),

    ('메르세데스-벤츠','E-클래스','W214','expert_commentary','오토뷰',
     '[BMW G60 520i & 메르세데스-벤츠 W214 E200] 답변 드립니다.',
     'https://www.autoview.co.kr/ko-kr/boards/2/79529',
     date '2026-09-13',date '2026-09-27','김기태 PD','E200',null,
     'W214 E200의 승차감·편안함·세팅을 G60 520i와 비교한 전문가 답변. 정식 로드테스트가 아니므로 B 참고자료로 분류한다.',
     'B','approved_reference','unique',false,false),

    ('테슬라','Model Y','주니퍼','expert_commentary','오토뷰',
     '[테슬라 모델Y 주니퍼 타이어 교체] 답변 드립니다.',
     'https://www.autoview.co.kr/ko-kr/boards/2/79080',
     date '2026-07-27',date '2026-09-27','김기태 PD','전기','주니퍼',
     'Model Y 주니퍼의 2열 승차감과 서스펜션 특성, 타이어 영향에 대한 전문가 답변. 정식 계측 시승이 아니므로 B 참고자료다.',
     'B','approved_reference','unique',false,false)
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
