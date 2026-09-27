begin;

with src(
  brand, model, generation_code, source_type, source_name, title, canonical_url,
  published_date, observed_date, author_label, powertrain_hint, trim_hint,
  summary, source_confidence, approval_status, dedupe_status,
  owner_claimed, owner_verified
) as (
  values
    ('제네시스','GV60','JW','expert_road_test','오토뷰',
     '제네시스 GV60 리뷰 [1207회]',
     'https://www.autoview.co.kr/ko-kr/articles/95914',
     date '2025-06-09',date '2026-09-27','오토뷰 로드테스트팀','전기',null,
     'JW GV60 전문 로드테스트 원문. 전기 파워트레인과 주행·상품성 평가 근거로 등록한다.',
     'A','approved_reference','unique',false,false),

    ('제네시스','G90','RS4','expert_road_test','오토뷰',
     '제네시스 G90 롱휠베이스 리뷰 [1060회]',
     'https://www.autoview.co.kr/ko-kr/articles/90564',
     date '2024-02-28',date '2026-09-27','오토뷰 로드테스트팀','3.5T AWD 48V e-S/C','롱휠베이스',
     'RS4 G90 롱휠베이스 전문 로드테스트. 3.5 터보 AWD와 48V 전동 슈퍼차저 사양의 주행 특성을 다룬다.',
     'A','approved_reference','unique',false,false),

    ('기아','EV5','EV5','expert_road_test','오토뷰',
     '2026 기아 EV5 롱레인지 리뷰 [1293회]',
     'https://www.autoview.co.kr/ko-kr/articles/101501',
     date '2026-08-27',date '2026-09-27','오토뷰 로드테스트팀','전기 2WD','GT-Line 롱레인지',
     'EV5 롱레인지 2WD GT-Line 전문 계측 리뷰. 가속·제동·중량·정숙성·효율과 승차감 평가가 포함된다.',
     'A','approved_reference','unique',false,false),

    ('기아','EV5','EV5','expert_road_test','오토뷰',
     '기아 EV5 롱레인지 2WD GT-Line 시승기',
     'https://www.autoview.co.kr/ko-kr/articles/101572',
     date '2026-09-03',date '2026-09-27','김기태 편집장','전기 2WD','GT-Line 롱레인지',
     'EV5 롱레인지 GT-Line의 실제 도로 시승기. 전문 계측 리뷰와 별개로 주행감·공간·완성도에 대한 해설을 제공한다.',
     'A','approved_reference','unique',false,false),

    ('현대','스타리아','US4','expert_road_test','오토뷰',
     '2026 현대 스타리아 라운지 하이브리드 리뷰 [1272회]',
     'https://www.autoview.co.kr/ko-kr/articles/100050',
     date '2026-05-05',date '2026-09-27','오토뷰 로드테스트팀','1.6T 하이브리드','라운지 7인승 인스퍼레이션',
     'US4 스타리아 라운지 하이브리드 전문 계측 리뷰. 가속·제동·중량·정숙성과 다인승 승차감을 평가한다.',
     'A','approved_reference','unique',false,false),

    ('르노코리아','XM3/아르카나','LJL','expert_road_test','오토뷰',
     '기아 셀토스 vs 르노삼성 XM3 동급 모델 비교',
     'https://www.autoview.co.kr/ko-kr/articles/71797',
     date '2020-09-29',date '2026-09-27','오토뷰 로드테스트팀',null,'XM3 초기형',
     'LJL XM3와 셀토스를 동일 조건에서 비교한 전문 자료. 차체·공간·주행·상품성 비교 근거로 사용한다.',
     'A','approved_reference','unique',false,false),

    ('기아','EV4','EV4','expert_commentary','오토뷰',
     '기아 EV4 & EV5 답변',
     'https://www.autoview.co.kr/ko-kr/boards/2/77106',
     date '2026-02-26',date '2026-09-27','김기태 PD','전기',null,
     'EV4와 EV5의 실제 주행 안정성·차체 움직임 차이를 설명한 전문가 답변. 정식 로드테스트가 아니므로 B 참고자료로 분류한다.',
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
join public.manufacturers mf on mf.name = s.brand
join public.car_models cm on cm.manufacturer_id = mf.id and cm.name = s.model
join public.generations g on g.car_model_id = cm.id
 and g.generation_code is not distinct from s.generation_code
on conflict (canonical_url) do update set
  generation_id = excluded.generation_id,
  source_type = excluded.source_type,
  source_name = excluded.source_name,
  title = excluded.title,
  published_date = excluded.published_date,
  observed_date = excluded.observed_date,
  author_label = excluded.author_label,
  powertrain_hint = excluded.powertrain_hint,
  trim_hint = excluded.trim_hint,
  summary = excluded.summary,
  source_confidence = excluded.source_confidence,
  approval_status = excluded.approval_status,
  dedupe_status = excluded.dedupe_status,
  owner_claimed = excluded.owner_claimed,
  owner_verified = excluded.owner_verified,
  owner_score_eligible = false,
  value_score_eligible = false,
  updated_at = now();

commit;
