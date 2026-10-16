begin;

with src(
  brand, model, source_type, source_name, title, canonical_url,
  published_date, observed_date, author_label, powertrain_hint, trim_hint,
  summary, source_confidence, approval_status, dedupe_status,
  owner_claimed, owner_verified
) as (
  values
    ('기아','EV4','expert_road_test','오토뷰',
     '기아 EV4 롱레인지 리뷰 [1201회]',
     'https://www.autoview.co.kr/ko-kr/articles/95660',
     date '2025-05-17',date '2026-09-27','오토뷰 로드테스트팀','전기 2WD','롱레인지 어스',
     'EV4 롱레인지 어스 전문 로드테스트. 현행 EV4 세대의 주행·상품성 외부근거로 등록한다.',
     'A','approved_reference','unique',false,false),

    ('기아','EV5','expert_road_test','오토뷰',
     '2026 기아 EV5 롱레인지 리뷰 [1293회]',
     'https://www.autoview.co.kr/ko-kr/articles/101501',
     date '2026-08-27',date '2026-09-27','오토뷰 로드테스트팀','전기 2WD','GT-Line 롱레인지',
     'EV5 롱레인지 2WD GT-Line 전문 계측 리뷰. 가속·제동·중량·정숙성·효율과 승차감 평가가 포함된다.',
     'A','approved_reference','unique',false,false),

    ('현대','캐스퍼','expert_road_test','오토뷰',
     '현대 캐스퍼 일렉트릭 [1164회]',
     'https://www.autoview.co.kr/ko-kr/articles/93677',
     date '2024-11-25',date '2026-09-27','오토뷰 로드테스트팀','전기','인스퍼레이션 17인치',
     'AX1 캐스퍼 일렉트릭 전문 로드테스트. 현행 캐스퍼 세대의 전기 파워트레인 평가 근거로 등록한다.',
     'A','approved_reference','unique',false,false),

    ('KGM','코란도','expert_road_test','오토뷰',
     '쌍용 코란도 1.6 디젤 시승기',
     'https://www.autoview.co.kr/ko-kr/articles/68063',
     null,date '2026-09-27','오토뷰 로드테스트팀','1.6 디젤','C300',
     'C300 코란도 전문 시승기. 차체·실내·주행 기본기와 디젤 파워트레인을 평가한다.',
     'A','approved_reference','unique',false,false),

    ('KGM','코란도','expert_road_test','오토뷰',
     '쌍용 코란도 가솔린 1.5 T 4WD 시승기',
     'https://www.autoview.co.kr/ko-kr/articles/69331',
     date '2019-11-19',date '2026-09-27','오토뷰 로드테스트팀','1.5T 가솔린 4WD','C300',
     'C300 코란도 가솔린 터보 4WD 전문 시승기. 동일 세대의 다른 파워트레인 근거로 별도 보존한다.',
     'A','approved_reference','unique',false,false),

    ('KGM','티볼리','expert_road_test','오토뷰',
     '쌍용 베리 뉴 티볼리 1.5 T-GDi 4WD 시승기',
     'https://www.autoview.co.kr/ko-kr/articles/68597',
     date '2019-08-26',date '2026-09-27','오토뷰 로드테스트팀','1.5T 가솔린 4WD','X100',
     'X100 티볼리 부분변경 1.5 터보 4WD 전문 시승기. 현행 세대의 외부 평가 근거로 등록한다.',
     'A','approved_reference','unique',false,false),

    ('KGM','렉스턴','expert_road_test','오토뷰',
     '쌍용 G4 렉스턴 시승기',
     'https://www.autoview.co.kr/ko-kr/articles/61996',
     date '2017-07-18',date '2026-09-27','오토뷰 로드테스트팀','2.2 디젤 4WD','Y400',
     'Y400 렉스턴 전문 로드테스트. 정숙성·가속·제동·온로드/오프로드 특성과 공간을 종합 평가한다.',
     'A','approved_reference','unique',false,false),

    ('기아','모닝','expert_road_test','오토뷰',
     '기아 모닝 & 쉐보레 스파크 비교 시승기',
     'https://www.autoview.co.kr/ko-kr/articles/61408',
     date '2017-05-02',date '2026-09-27','오토뷰 로드테스트팀','1.0 가솔린','JA',
     'JA 3세대 모닝과 쉐보레 스파크를 비교한 전문 시승기. 차체·가격·주행 완성도 비교 근거로 사용한다.',
     'A','approved_reference','unique',false,false),

    ('기아','셀토스','expert_road_test','오토뷰',
     '기아 셀토스 1.6 T 4WD 시승기',
     'https://www.autoview.co.kr/ko-kr/articles/68626',
     null,date '2026-09-27','오토뷰 로드테스트팀','1.6T 4WD','SP2',
     'SP2 셀토스 초기형 1.6 터보 4WD 전문 시승기. 승차감·주행 안정성·가격과 상품성을 평가한다.',
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
join public.manufacturers mf on mf.name = s.brand
join public.car_models cm on cm.manufacturer_id = mf.id and cm.name = s.model
join public.generations g on g.car_model_id = cm.id and g.current = true
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
