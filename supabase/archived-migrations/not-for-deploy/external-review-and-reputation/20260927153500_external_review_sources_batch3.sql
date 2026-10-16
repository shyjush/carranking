begin;

with src(
  brand, model, generation_code, source_type, source_name, title, canonical_url,
  published_date, observed_date, author_label, powertrain_hint, trim_hint,
  summary, source_confidence, approval_status, dedupe_status,
  owner_claimed, owner_verified
) as (
  values
    ('현대','아이오닉 5','NE','expert_road_test','오토뷰',
     '현대 아이오닉 5 N [1116회]',
     'https://www.autoview.co.kr/ko-kr/articles/90811',
     date '2024-03-20',date '2026-09-27','오토뷰 로드테스트팀','전기 AWD','아이오닉 5 N',
     'NE 아이오닉 5 N 전문 로드테스트. 4륜구동 고성능 전기 파워트레인과 N 특화 주행 특성을 다룬다.',
     'A','approved_reference','unique',false,false),

    ('현대','아이오닉 6','CE','expert_road_test','오토뷰',
     '현대 아이오닉 6 리뷰 [1054회]',
     'https://www.autoview.co.kr/ko-kr/articles/90573',
     date '2024-02-28',date '2026-09-27','오토뷰 로드테스트팀','롱레인지 AWD',null,
     'CE 아이오닉 6 롱레인지 AWD 전문 로드테스트. 전기 세단의 주행·효율·정숙성·상품성을 평가한다.',
     'A','approved_reference','unique',false,false),

    ('현대','아이오닉 6','CE','expert_road_test','오토뷰',
     '2026 현대 아이오닉 6 N 리뷰 / 중앙일보 COTY x 오토뷰',
     'https://www.autoview.co.kr/ko-kr/articles/100025',
     date '2026-03-17',date '2026-09-27','오토뷰 로드테스트팀','전기 AWD','아이오닉 6 N',
     'CE 아이오닉 6 N 전문 계측 리뷰. 가속·제동·중량·정숙성과 고성능 EV 섀시 및 주행 완성도를 다룬다.',
     'A','approved_reference','unique',false,false),

    ('제네시스','G70','IK','expert_road_test','오토뷰',
     '[시승기] 제네시스, G70 2.0T HTRAC',
     'https://www.autoview.co.kr/ko-kr/articles/63271',
     null,date '2026-09-27','오토뷰 로드테스트팀','2.0T AWD','HTRAC',
     'IK G70 2.0T HTRAC 전문 시승기. 주행성능·편의장비·가격과 상품성을 종합 평가한다.',
     'A','approved_reference','unique',false,false),

    ('제네시스','G70','IK','expert_road_test','모터그래프',
     '[시승기] 제네시스 G70 외모가 다는 아니잖아요!',
     'https://www.motorgraph.com/news/articleView.html?idxno=27147',
     date '2021-02-15',date '2026-09-27','박홍준','3.3T AWD','페이스리프트',
     'IK G70 페이스리프트 3.3 터보 AWD 시승기. 가속·코너링·제동·소음과 주행 감각을 평가한다.',
     'A','approved_reference','unique',false,false),

    ('기아','니로','DE','expert_road_test','오토뷰',
     '[시승기] 기아, 니로',
     'https://www.autoview.co.kr/ko-kr/articles/59229',
     date '2016-07-26',date '2026-09-27',null,'하이브리드','1세대',
     'DE 1세대 니로 전문 시승기. 공간·하이브리드 저속 특성·승차감과 효율을 다룬 초기 세대 평가자료다.',
     'A','approved_reference','unique',false,false),

    ('제네시스','G70','IK','expert_road_test','모터그래프',
     '[시승기] 제네시스 G70 3.3 트윈터보의 가치와 2019년형의 변화',
     'https://www.motorgraph.com/news/articleView.html?idxno=21282',
     date '2018-12-17',date '2026-09-27','전승용','3.3T','2019년형',
     'IK G70 3.3 트윈터보 2019년형 전문 시승기. 고성능 파워트레인과 상품성 변화를 평가한다.',
     'A','approved_reference','unique',false,false),

    ('제네시스','G70','IK','expert_commentary','오토뷰',
     '[제네시스 G70 & G80 & 기아 K9] 답변 드립니다.',
     'https://www.autoview.co.kr/ko-kr/boards/2/79134',
     date '2026-08-08',date '2026-09-27','김기태 PD','3.3T',null,
     'G70 3.3T의 운전 재미·고속 안정성 및 경쟁 차종과의 성격 차이에 대한 전문가 답변. 보조 참고자료로 분류한다.',
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
join public.generations g on g.car_model_id = cm.id and g.generation_code = s.generation_code
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
