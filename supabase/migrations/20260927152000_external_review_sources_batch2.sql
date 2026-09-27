begin;

with src(
  brand, model, generation_code, source_type, source_name, title, canonical_url,
  published_date, observed_date, author_label, powertrain_hint, trim_hint,
  summary, source_confidence, approval_status, dedupe_status,
  owner_claimed, owner_verified
) as (
  values
    ('기아','K8','GL3','expert_road_test','오토뷰',
     '이 정도면 돈 값하는... 기아 K8 하이브리드 리뷰 [1288회]',
     'https://www.autoview.co.kr/ko-kr/articles/101146',
     date '2026-07-25',date '2026-09-27','오토뷰 로드테스트팀','1.6T 하이브리드','시그니처',
     '2026년형 K8 하이브리드 전문 계측 로드테스트. 가속·제동·중량·정숙성·가격과 주행 특성을 함께 확인할 수 있다.',
     'A','approved_reference','unique',false,false),

    ('기아','쏘렌토','MQ4','expert_road_test','오토뷰',
     '기아 쏘렌토 1.6T 하이브리드 리뷰 [1231회]',
     'https://www.autoview.co.kr/ko-kr/articles/97497',
     date '2025-10-18',date '2026-09-27','오토뷰 로드테스트팀','1.6T 하이브리드 AWD','유럽 사양',
     '유럽 판매 사양 MQ4 하이브리드 전문 로드테스트. 섀시 밸런스·승차감·공간과 유지비 관점 평가가 포함된다.',
     'A','approved_reference','unique',false,false),

    ('기아','쏘렌토','MQ4','expert_road_test','오토뷰',
     '기아 쏘렌토 1.6T 하이브리드 리뷰 [1185회]',
     'https://www.autoview.co.kr/ko-kr/articles/94544',
     date '2025-02-24',date '2026-09-27','오토뷰 로드테스트팀','1.6T 하이브리드','5인승',
     'MQ4 쏘렌토 하이브리드 5인승 전문 로드테스트 자료. 동일 세대의 별도 시점 평가 근거로 보존한다.',
     'A','approved_reference','unique',false,false),

    ('현대','싼타페','MX5','expert_road_test','오토뷰',
     '현대 싼타페 2.5T 2WD 리뷰 [1088회]',
     'https://www.autoview.co.kr/ko-kr/articles/90516',
     date '2024-02-27',date '2026-09-27','오토뷰 로드테스트팀','2.5T 2WD',null,
     '5세대 MX5 싼타페 2.5 터보 전문 로드테스트. 공간과 가솔린 터보 주행 특성을 확인할 수 있는 외부 평가 근거다.',
     'A','approved_reference','unique',false,false),

    ('기아','카니발','KA4','expert_road_test','오토뷰',
     '기아 카니발 1.6T 하이브리드 리뷰 [1245회]',
     'https://www.autoview.co.kr/ko-kr/articles/98514',
     date '2025-12-25',date '2026-09-27','오토뷰 로드테스트팀','1.6T 하이브리드','7인승 X-Line',
     'KA4 카니발 하이브리드 전문 계측 리뷰. 가속·제동·중량·정숙성·공간·승차감과 가격 평가가 포함된다.',
     'A','approved_reference','unique',false,false),

    ('현대','그랜저','GN7','expert_road_test','오토뷰',
     '현대 그랜저 1.6T 하이브리드 리뷰 [1038회]',
     'https://www.autoview.co.kr/ko-kr/articles/90588',
     date '2024-02-28',date '2026-09-27','오토뷰 로드테스트팀','1.6T 하이브리드',null,
     'GN7 그랜저 하이브리드 전문 로드테스트. 하이브리드 파워트레인 성능과 차체 특성 평가 근거다.',
     'A','approved_reference','unique',false,false),

    ('현대','그랜저','GN7','expert_road_test','오토뷰',
     '현대 그랜저 3.5 AWD & 3.5 LPI 리뷰 [1037회]',
     'https://www.autoview.co.kr/ko-kr/articles/90589',
     date '2024-02-28',date '2026-09-27','오토뷰 로드테스트팀','3.5 AWD / 3.5 LPI',null,
     'GN7 그랜저 3.5 AWD 및 3.5 LPI 파워트레인을 다룬 전문 로드테스트. 동일 세대 파워트레인별 참고자료다.',
     'A','approved_reference','unique',false,false),

    ('현대','아반떼','CN7','expert_road_test','오토뷰',
     '현대 아반떼 1.6 리뷰 [1058회]',
     'https://www.autoview.co.kr/ko-kr/articles/90566',
     date '2024-02-28',date '2026-09-27','오토뷰 로드테스트팀','1.6 가솔린','부분변경',
     'CN7 부분변경 아반떼 1.6 전문 로드테스트. 기본 파워트레인과 섀시 상품성 평가자료다.',
     'A','approved_reference','unique',false,false),

    ('기아','스포티지','NQ5','expert_road_test','오토뷰',
     '기아 스포트지 1.6T 리뷰 [1175회]',
     'https://www.autoview.co.kr/ko-kr/articles/94165',
     date '2025-01-13',date '2026-09-27','오토뷰 로드테스트팀','1.6T 가솔린',null,
     'NQ5 스포티지 1.6 터보 전문 로드테스트 원문. 세대별 주행 및 상품성 평가 참고자료로 활용한다.',
     'A','approved_reference','unique',false,false),

    ('현대','쏘나타','DN8','expert_road_test','오토뷰',
     '현대 쏘나타 1.6 터보 리뷰 [1076회]',
     'https://www.autoview.co.kr/ko-kr/articles/90528',
     date '2024-02-27',date '2026-09-27','오토뷰 로드테스트팀','1.6T 가솔린','디 엣지',
     'DN8 쏘나타 디 엣지 1.6 터보 전문 로드테스트. 부분변경 이후 상품성과 주행 특성을 다룬다.',
     'A','approved_reference','unique',false,false),

    ('현대','투싼','NX4','expert_road_test','오토뷰',
     '현대 투싼 1.6T 하이브리드 리뷰 [1243회]',
     'https://www.autoview.co.kr/ko-kr/articles/98372',
     date '2025-12-09',date '2026-09-27','오토뷰 로드테스트팀','1.6T 하이브리드','Inspiration',
     'NX4 투싼 하이브리드 전문 계측 리뷰. 가속·제동·중량·정숙성과 섀시 밸런스·승차감 평가가 포함된다.',
     'A','approved_reference','unique',false,false),

    ('현대','코나','SX2','expert_road_test','오토뷰',
     '현대 코나 1.6T 리뷰 [1052회]',
     'https://www.autoview.co.kr/ko-kr/articles/90570',
     date '2024-02-28',date '2026-09-27','오토뷰 로드테스트팀','1.6T 가솔린',null,
     '2세대 SX2 코나 1.6 터보 전문 로드테스트. 세대 변경 이후 주행·상품성 평가 근거다.',
     'A','approved_reference','unique',false,false),

    ('현대','팰리세이드','LX3','expert_road_test','오토뷰',
     '[시승기] 2025 현대 팰리세이드 9인승 2.5T (FWD)',
     'https://www.autoview.co.kr/ko-kr/articles/94444',
     date '2025-02-13',date '2026-09-27','전인호 기자','2.5T FWD','9인승',
     '2세대 LX3 팰리세이드 9인승 2.5 터보 시승기. 공간·승차감·주행 및 대형 SUV 상품성을 평가한다.',
     'A','approved_reference','unique',false,false),

    ('기아','레이','TAM','expert_road_test','오토뷰',
     '[시승기] 2024 레이 EV (Ray EV)',
     'https://www.autoview.co.kr/ko-kr/articles/91481',
     date '2024-05-13',date '2026-09-27','전인호 기자','전기','레이 EV',
     'TAM 레이 EV 전문 시승기. 공간 활용성·도심 운용·전기 파워트레인 특성을 확인할 수 있다.',
     'A','approved_reference','unique',false,false),

    ('기아','K5','DL3','expert_road_test','오토뷰',
     '2024 기아 K5 2.0 리뷰 [1102회]',
     'https://www.autoview.co.kr/ko-kr/articles/90010',
     date '2024-01-09',date '2026-09-27','오토뷰 로드테스트팀','2.0 가솔린','부분변경',
     'DL3 K5 부분변경 2.0 가솔린 전문 계측 리뷰. 가속·제동을 포함한 기본형 파워트레인 평가 근거다.',
     'A','approved_reference','unique',false,false),

    ('제네시스','GV70','JK1','expert_road_test','오토뷰',
     '[시승기] 제네시스, GV70 2.5 AWD',
     'https://www.autoview.co.kr/ko-kr/articles/73662',
     date '2021-05-12',date '2026-09-27','오토뷰 로드테스트팀','2.5T AWD',null,
     'JK1 GV70 초기형 2.5 AWD 전문 시승기. 디자인·고속주행·조향·가격 및 패키징을 종합 평가한다.',
     'A','approved_reference','unique',false,false),

    ('제네시스','G80','RG3','expert_road_test','모터그래프',
     '[시승기] 2세대 오너가 본 3세대 G80…“진정한 환골탈태”',
     'https://www.motorgraph.com/news/articleView.html?idxno=25684',
     date '2020-06-08',date '2026-09-27','권지용',null,null,
     'DH 장기 운용 경험이 있는 기자가 RG3 G80을 시승하며 세대 변화와 디자인·실내·주행 특성을 비교 평가한 전문 시승기다.',
     'A','approved_reference','unique',false,false),

    ('제네시스','GV70','JK1','expert_road_test','모터그래프',
     '[시승기] 제네시스 GV70, “합리적 대안이 아닌 주류다”',
     'https://www.motorgraph.com/news/articleView.html?idxno=27479',
     date '2021-04-12',date '2026-09-27','박홍준','3.5T AWD',null,
     'JK1 GV70 전문 시승기. 고속 주행·곡선 거동·정숙성·공간과 가격 구성을 함께 평가한다.',
     'A','approved_reference','unique',false,false),

    ('기아','EV9','MV','expert_road_test','모터그래프',
     'EV9 살 때 꼭 알아야 할 9가지 특징…가격만 저렴했어도! [시승기]',
     'https://www.motorgraph.com/news/articleView.html?idxno=33144',
     date '2023-12-20',date '2026-09-27','권지용','전기 AWD','어스 6인승',
     'MV EV9 실제 시승을 바탕으로 공간·주행·가격·편의성 등 구매 전 확인할 특성을 정리한 전문 평가자료다.',
     'A','approved_reference','unique',false,false),

    ('제네시스','GV70','JK1','expert_commentary','오토뷰',
     '[제네시스 GV70] 답변 드립니다.',
     'https://www.autoview.co.kr/ko-kr/boards/2/75811',
     date '2025-03-28',date '2026-09-27','김기태 PD',null,null,
     'GV70의 스티어링·서스펜션·안정감 및 국내외 개발환경 차이에 대한 전문 질의응답. 완결된 로드테스트가 아니므로 B 참고자료로 분류한다.',
     'B','approved_reference','unique',false,false),

    ('기아','K9','RJ','expert_commentary','오토뷰',
     '[기아 K9] 답변 드립니다.',
     'https://www.autoview.co.kr/ko-kr/boards/2/79125',
     date '2026-08-08',date '2026-09-27','김기태 PD',null,'2세대',
     '2세대 K9의 시장 포지션·승차감·제동·코너링·중고차 가치 관점에 대한 전문가 답변. 로드테스트가 아닌 보조 참고자료다.',
     'B','approved_reference','unique',false,false),

    ('현대','싼타페','MX5','expert_commentary','오토뷰',
     '[기아 쏘렌토 & 현대 싼타페 & 투싼] 답변 드립니다.',
     'https://www.autoview.co.kr/ko-kr/boards/2/71329',
     date '2024-10-27',date '2026-09-27','김기태 PD',null,null,
     '싼타페·쏘렌토·투싼의 승차감·고급화·셋업 차이를 비교한 전문가 답변. MX5 보조 평가 근거로 사용한다.',
     'B','approved_reference','unique',false,false),

    ('기아','카니발','KA4','expert_commentary','오토뷰',
     '[기아 카니발 & EV5 & 르노 필랑트 & 모델 Y] 답변 드립니다.',
     'https://www.autoview.co.kr/ko-kr/boards/2/79568',
     date '2026-09-20',date '2026-09-27','김기태 PD',null,null,
     'KA4 카니발의 공간·슬라이딩도어 장점과 2열 승차감 특성을 설명한 최신 전문가 답변. B 참고자료로 분류한다.',
     'B','approved_reference','unique',false,false),

    ('기아','K8','GL3','owner_report_unverified','오토뷰',
     'K8 2.5 적정 휠 사이즈 조언 부탁드립니다.',
     'https://www.autoview.co.kr/ko-kr/boards/2/76658',
     date '2025-10-09',date '2026-09-27','shael2420','2.5 가솔린','구형 K8',
     '작성자가 K8 2.5를 구매·운용 중이라고 밝히며 타이어와 주행 안정감 경험을 공유한 글. CarRanking 실소유 인증 전까지 C/보류한다.',
     'C','hold','unique',true,false),

    ('제네시스','GV80','JX1','owner_report_unverified','오토뷰',
     '오토뷰 타이어 리뷰는 역시 최고네요.',
     'https://www.autoview.co.kr/ko-kr/boards/2/78666',
     date '2026-05-20',date '2026-09-27','naver_5qz4jlbb','3.0 디젤 AWD',null,
     '작성자가 GV80 3.0 디젤 사륜을 운용하며 타이어 교체 경험을 공유한 글. 차량 소유 증빙은 확인되지 않아 C/보류한다.',
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
