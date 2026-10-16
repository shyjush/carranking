begin;

with src(brand,model,generation_code,use_current,title,url,published_date,author_label,powertrain,summary) as (
values
('BMW','5시리즈','G60',false,
 '520i 약 1년 후기',
 'https://www.autoview.co.kr/ko-kr/boards/3/76975',
 date '2026-01-15','major83','520i M Sport',
 '작성자가 2025년 2월 520i M Sport를 인수해 약 1년, 약 6,000km 운용했다고 밝히며 승차감·연비·정숙성·핸들링·공간을 공유한 사용자 경험 글.'),

('기아','EV4',null,true,
 'EV4 출고 후기',
 'https://www.autoview.co.kr/ko-kr/boards/3/76651',
 date '2025-10-06','okaycik','EV4 어스 17인치',
 '작성자가 EV4를 장기렌트 세컨카로 직접 출고해 옵션·가감속·승차감·타이어·전비와 고속주행 경험을 공유한 글.'),

('기아','K3','BD',false,
 'K3 GT 시승기 밀린 기념으로 느낌 및 몇가지 질문',
 'https://www.autoview.co.kr/ko-kr/boards/3/8',
 date '2019-07-12','win3020','K3 GT',
 '작성자가 K3 GT를 출고하고 길들이기 주행 중 연비·시트·고속 진출입구 거동 등 초기 사용 경험을 공유한 글.'),

('볼보','XC40','CMA',false,
 '[볼보 XC40] 실 사용기 (1.5년)',
 'https://www.autoview.co.kr/ko-kr/boards/3/70',
 date '2022-07-22','junos','XC40 B4',
 '작성자가 약 1년 8개월, 약 8,000km 운용한 XC40의 연비·승차감·정숙성·잔고장 등 장기 사용 경험을 공유한 글.'),

('토요타','캠리','XV80',false,
 '토요타 9세대 캠리 XLE feat.프리우스 5세대',
 'https://www.autoview.co.kr/ko-kr/boards/3/76817',
 date '2025-12-05','bbbig','9세대 캠리 XLE',
 '작성자가 배우자 차량을 9세대 캠리로 교체했다고 밝히며 프리우스와 비교한 선택 과정과 실제 사용 관점을 공유한 글.'),

('기아','쏘렌토','MQ4',false,
 '쏘렌토 하이브리드 시승기 올립니다',
 'https://www.autoview.co.kr/ko-kr/boards/3/34',
 date '2020-11-12','major83','쏘렌토 하이브리드 2WD 6인승 시그니처',
 '작성자가 MQ4 쏘렌토 하이브리드를 직접 계약·구입한 뒤 초기 운용 경험과 선택 배경을 공유한 사용자 후기.'),

('르노코리아','SM6','LFD',false,
 '떠나보낼 차를 소개합니다.(SM6 TCE300)',
 'https://www.autoview.co.kr/ko-kr/boards/3/77262',
 date '2026-04-06','talisagera','SM6 TCe300',
 '작성자가 장기간 운용한 SM6 TCe300을 처분하기 전 파워트레인·주행·편의장비·연비 등 실사용 경험을 정리한 글.')
)
insert into public.external_review_sources(
 generation_id,source_type,source_name,title,canonical_url,published_date,observed_date,
 author_label,powertrain_hint,summary,source_confidence,approval_status,dedupe_status,
 owner_claimed,owner_verified,owner_score_eligible,value_score_eligible)
select
 g.id,'owner_report_unverified','오토뷰 내 차를 소개합니다',s.title,s.url,s.published_date,date '2026-09-27',
 s.author_label,s.powertrain,s.summary,'C','hold','unique',true,false,false,false
from src s
join public.manufacturers mf on mf.name=s.brand
join public.car_models cm on cm.manufacturer_id=mf.id and cm.name=s.model
join public.generations g on g.car_model_id=cm.id
 and ((not s.use_current and g.generation_code=s.generation_code) or (s.use_current and g.current=true))
on conflict(canonical_url) do update set
 generation_id=excluded.generation_id,
 source_type='owner_report_unverified',
 source_name=excluded.source_name,
 title=excluded.title,
 published_date=excluded.published_date,
 observed_date=excluded.observed_date,
 author_label=excluded.author_label,
 powertrain_hint=excluded.powertrain_hint,
 summary=excluded.summary,
 source_confidence='C',
 approval_status='hold',
 dedupe_status='unique',
 owner_claimed=true,
 owner_verified=false,
 owner_score_eligible=false,
 value_score_eligible=false,
 updated_at=now();

commit;
