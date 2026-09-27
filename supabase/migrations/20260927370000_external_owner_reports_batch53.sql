begin;

with src(brand,model,generation_code,source_name,title,url,published_date,author_label,powertrain,summary) as (
values
('기아','카니발','KA4','오토뷰 내 차를 소개합니다',
 '예상치 못한 빠른 출고가 되어 급히 카니발 하이브리드를 소개합니다',
 'https://www.autoview.co.kr/ko-kr/boards/3/70698',
 date '2024-05-11','desmond99','카니발 하이브리드 노블레스',
 '작성자가 KA4 카니발 하이브리드를 직접 출고해 약 400km 운행한 뒤 공간·정숙성·출력·브레이크·연비·옵션 경험을 공유한 초기 오너 후기.'),

('현대','아반떼','CN7','오토뷰 내 차를 소개합니다',
 'CN7 N라인, 1년 3개월동안 타면서 느낀 점들에 대한 리뷰',
 'https://www.autoview.co.kr/ko-kr/boards/3/70738',
 date '2024-05-21','joun0691','아반떼 CN7 N Line',
 '작성자가 CN7 N라인을 첫 차로 구매해 1년 3개월 보유하며 다른 차량과 비교한 주행·승차감·상품성 경험을 정리한 장기 오너 후기.'),

('BMW','5시리즈','G30','오토뷰 내 차를 소개합니다',
 'BMW G30 520d 럭셔리라인',
 'https://www.autoview.co.kr/ko-kr/boards/3/70436',
 date '2024-02-09','desmond99','G30 520d Luxury',
 '작성자가 2019년식 G30 520d를 직접 구매해 장거리 출퇴근 중심으로 운용하며 연비·가족 활용·주행 경험을 공유한 오너 후기.'),

('쉐보레','말리부','E2XX','오토뷰 내 차를 소개합니다',
 '21년식 말리부 1.35T 4000KM 주행 후기',
 'https://www.autoview.co.kr/ko-kr/boards/3/55',
 date '2021-09-08','wnsdud7123','말리부 1.35T',
 '작성자가 2021년식 E2XX 말리부 1.35T를 구매해 약 4,000km 주행한 뒤 디자인·파워트레인·주행·선택 배경을 공유한 오너 후기.'),

('기아','스포티지','NQ5','오토뷰 차량 및 타이어 Q&A',
 '스포티지 nq5 타이어 질문 드립니다.',
 'https://www.autoview.co.kr/ko-kr/boards/2/78606',
 date '2026-05-11','anysilver01','NQ5 디젤 AWD',
 '작성자가 2024년 9월 NQ5 디젤 AWD를 직접 구입했다고 밝히며 실제 운용 중 직진성·스티어링 특성 및 타이어 경험을 공유한 글. 질문 중심 자료이므로 보류만 유지.')
)
insert into public.external_review_sources(
 generation_id,source_type,source_name,title,canonical_url,published_date,observed_date,
 author_label,powertrain_hint,summary,source_confidence,approval_status,dedupe_status,
 owner_claimed,owner_verified,owner_score_eligible,value_score_eligible)
select
 g.id,'owner_report_unverified',s.source_name,s.title,s.url,s.published_date,date '2026-09-27',
 s.author_label,s.powertrain,s.summary,'C','hold','unique',true,false,false,false
from src s
join public.manufacturers mf on mf.name=s.brand
join public.car_models cm on cm.manufacturer_id=mf.id and cm.name=s.model
join public.generations g on g.car_model_id=cm.id and g.generation_code=s.generation_code
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
