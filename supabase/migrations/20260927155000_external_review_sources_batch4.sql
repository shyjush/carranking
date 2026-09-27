begin;

with src(
  brand, model, generation_code, source_type, source_name, title, canonical_url,
  published_date, observed_date, author_label, powertrain_hint, trim_hint,
  summary, source_confidence, approval_status, dedupe_status,
  owner_claimed, owner_verified
) as (
  values
    ('르노코리아','그랑 콜레오스',null,'expert_road_test','오토뷰',
     '2026년형 르노 그랑 콜레오스 E-Tech 리뷰 [1228회]',
     'https://www.autoview.co.kr/ko-kr/articles/97363',
     date '2025-10-07',date '2026-09-27','오토뷰 로드테스트팀','1.5T E-Tech 하이브리드','Esprit Alpine',
     '그랑 콜레오스 E-Tech 하이브리드 전문 계측 리뷰. 가속·제동·중량·정숙성·연비·승차감과 가격을 평가한다.',
     'A','approved_reference','unique',false,false),

    ('르노코리아','그랑 콜레오스',null,'expert_road_test','오토뷰',
     '[시승기] 르노 그랑 콜레오스 2.0 터보 FWD',
     'https://www.autoview.co.kr/ko-kr/articles/93583',
     date '2024-11-15',date '2026-09-27','전인호 기자','2.0T FWD','Iconic',
     '그랑 콜레오스 2.0 터보 전륜구동 전문 시승기. 핸들링·가속·승차감과 실내 상품성을 평가한다.',
     'A','approved_reference','unique',false,false),

    ('르노코리아','그랑 콜레오스',null,'expert_road_test','오토뷰',
     '르노 그랑 콜레오스 2.0T 4WD 리뷰 [1193회]',
     'https://www.autoview.co.kr/ko-kr/articles/95217',
     date '2025-04-14',date '2026-09-27','오토뷰 로드테스트팀','2.0T 4WD',null,
     '그랑 콜레오스 2.0 터보 4WD 전문 계측 리뷰. 전륜 모델과 구분되는 구동계 및 주행성능 근거다.',
     'A','approved_reference','unique',false,false),

    ('르노코리아','QM6','HZG','expert_road_test','오토뷰',
     '[시승기] 르노삼성 QM6 2.0 GDe & LPe',
     'https://www.autoview.co.kr/ko-kr/articles/72978',
     date '2021-02-23',date '2026-09-27',null,'2.0 GDe / LPe',null,
     'HZG QM6 가솔린 및 LPG 전문 시승기. 공간·가격·승차감·주행 기본기와 파워트레인 차이를 평가한다.',
     'A','approved_reference','unique',false,false),

    ('쉐보레','트랙스 크로스오버',null,'expert_road_test','오토뷰',
     '쉐보레 트랙스 크로스오버 리뷰 [1059회]',
     'https://www.autoview.co.kr/ko-kr/articles/90565',
     date '2024-02-28',date '2026-09-27','오토뷰 로드테스트팀','1.2T 가솔린','RS',
     '트랙스 크로스오버 RS 전문 로드테스트. 가성비와 소형 CUV 주행·상품성을 평가한다.',
     'A','approved_reference','unique',false,false),

    ('쉐보레','트랙스 크로스오버',null,'expert_road_test','모터그래프',
     '트랙스 크로스오버 vs 신형 코나…무엇을 사야 할까? [비교 시승기]',
     'https://www.motorgraph.com/news/articleView.html?idxno=32037',
     date '2023-04-26',date '2026-09-27','권지용','1.2T 가솔린',null,
     '트랙스 크로스오버와 코나의 비교 시승. 공간·옵션·주행·상품성을 같은 조건에서 비교한 전문 평가자료다.',
     'A','approved_reference','unique',false,false),

    ('쉐보레','트레일블레이저',null,'expert_road_test','오토뷰',
     '쉐보레 트레일블레이저 1.35T AWD 리뷰 [1039회]',
     'https://www.autoview.co.kr/ko-kr/articles/90587',
     date '2024-02-28',date '2026-09-27','오토뷰 로드테스트팀','1.35T AWD','RS',
     '트레일블레이저 1.35 터보 AWD 전문 로드테스트. 소형 SUV의 구동계와 섀시·승차감·성능을 평가한다.',
     'A','approved_reference','unique',false,false),

    ('KGM','토레스','J100','expert_road_test','오토뷰',
     'KGM 토레스 하이브리드 리뷰 [1204회]',
     'https://www.autoview.co.kr/ko-kr/articles/95798',
     date '2025-05-28',date '2026-09-27','오토뷰 로드테스트팀','하이브리드',null,
     'J100 토레스 하이브리드 전문 로드테스트. 하이브리드 파워트레인과 주행·상품성 평가자료다.',
     'A','approved_reference','unique',false,false),

    ('KGM','토레스 EVX',null,'expert_commentary','오토뷰',
     '[KGM 토레스 EVX] 답변 드립니다.',
     'https://www.autoview.co.kr/ko-kr/boards/1/76337',
     date '2025-07-12',date '2026-09-27','김기태 PD','전기',null,
     '토레스 EVX를 실제로 충분히 경험한 뒤 밝힌 전문가 코멘트. 정식 로드테스트가 제작되지 않아 B 보조 참고자료로만 사용한다.',
     'B','approved_reference','unique',false,false),

    ('르노코리아','그랑 콜레오스',null,'owner_report_unverified','오토뷰',
     '르노 그랑 콜레오스(내연 앞바퀴굴림) 1년 시승기',
     'https://www.autoview.co.kr/ko-kr/boards/3/77100',
     date '2026-02-26',date '2026-09-27','korbulo1','2.0T FWD',null,
     '작성자가 그랑 콜레오스를 약 1년 운용했다고 밝히며 조향·승차감 경험을 공유한 글. CarRanking 실소유 인증 전까지 C/보류한다.',
     'C','hold','unique',true,false)
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
