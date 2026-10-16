begin;

with src(brand,model,generation_code,use_current,title,url,published_date,author_label,powertrain,summary) as (
values
('메르세데스-벤츠','EQS','V297',false,
 'EQS 450+ 소개 한 번 해봅니다',
 'https://www.autoview.co.kr/ko-kr/boards/3/77241',
 date '2026-04-02','kkumool','EQS 450+',
 '작성자가 2024년 8월 인증중고 무주행 재고차를 인수해 약 1년 8개월, 약 3만km 운용했다고 밝히며 NVH·주행거리·공간·ADAS·타이어·차고를 평가한 장기 경험 글.'),

('포드','레인저','P703',false,
 '포드 레인저 랩터 10개월 주행기',
 'https://www.autoview.co.kr/ko-kr/boards/3/77231',
 date '2026-03-29','ydy6780','레인저 랩터',
 '작성자가 레인저 랩터를 데일리카로 약 10개월 운용하며 파워트레인·연비·제동·FOX 서스펜션·핸들링·공간·오프로드 특성을 공유한 글.'),

('볼보','EX30',null,true,
 'EX30 CC 한달 후기입니다',
 'https://www.autoview.co.kr/ko-kr/boards/3/78951',
 date '2026-06-27','suntorypm','EX30 Cross Country',
 '작성자가 EX30 CC를 한 달 운용하며 주행안정성·가속/제동·승차감·공간·핸들링·ADAS·충전 경험을 공유한 글.'),

('폭스바겐','골프','MK8',false,
 '8.5 골프 GTI를 소개합니다',
 'https://www.autoview.co.kr/ko-kr/boards/3/76545',
 date '2025-09-03','sdc921','Golf GTI 8.5',
 '작성자가 골프 GTI 8.5세대를 출고해 약 2개월 조금 넘게 6,600km 주행하며 핸들링·연비·서스펜션·편의성 경험을 공유한 글.'),

('포르쉐','911','992',false,
 '992.1 4GTS 카브리올레 입니다',
 'https://www.autoview.co.kr/ko-kr/boards/3/77467',
 date '2026-04-30','happymuc81','992.1 Carrera 4 GTS Cabriolet',
 '작성자가 992.1 4GTS 카브리올레를 약 2년 보유했다고 밝히며 고속안정성·와인딩·PDK·승차감·편의성 등 장기 사용 경험을 공유한 글.'),

('포르쉐','911','992',false,
 '992.2 GT3 투어링을 출고했습니다',
 'https://www.autoview.co.kr/ko-kr/boards/3/78959',
 date '2026-06-29','happymuc81','992.2 GT3 Touring',
 '작성자가 992.2 GT3 투어링을 직접 출고하고 초기 약 300km 주행 뒤 스로틀 응답·트랙션·NVH·승차감·편의성 등을 992.1 4GTS와 비교한 초기 오너 경험 글.'),

('쉐보레','크루즈','J300',false,
 '2014 쉐보레 크루즈 디젤 - 20만km를 함께한 오너의 솔직한 이야기',
 'https://www.autoview.co.kr/ko-kr/boards/3/71717',
 date '2025-02-13','hyeonwook321','크루즈 디젤',
 '작성자가 2019년 7월부터 2023년 11월까지 약 20만km 운용했다고 밝히며 토크·주행감각·차대·핸들링 등 장기 사용 경험을 정리한 글.')
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
