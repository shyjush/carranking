begin;

with src(brand,model,generation_code,source_name,title,url,published_date,author_label,powertrain,summary) as (
values
('기아','K5','DL3','데일리안',
 '[시승기] 더 뉴 K5 "나 얼굴 고쳤는데 어때?"(feat. 원판)',
 'https://www.dailian.co.kr/news/view/1325976/%EC%8B%9C%EC%8A%B9%EA%B8%B0-%EB%8D%94-%EB%89%B4-K5-%EB%82%98-%EC%96%BC%EA%B5%B4-%EA%B3%A0%EC%B3%A4%EB%8A%94%EB%8D%B0-2024',
 date '2024-02-12','박영국','2.0 가솔린 시그니처',
 'DL3 부분변경 K5를 5박6일 약 500km 주행하며 시내·고속도로·국도·와인딩에서 승차감·공간·주행감을 평가한 독립 시승자료.'),

('기아','스포티지','NQ5','모터그래프',
 '울컥거리는 DCT 버린 효과 있을까?! 7단 DCT 구형 스포티지 vs 8단 자동 신형 스포티지 비교 시승기!',
 'https://www.motorgraph.com/news/articleView.html?idxno=41420',
 date '2024-12-26','모터그래프','1.6T 가솔린 8AT',
 'NQ5 부분변경 신형 8단 자동과 기존 7단 DCT를 직접 비교해 변속감·가속·일상 주행 특성을 평가한 독립 비교시승.'),

('현대','팰리세이드','LX3','현대경제신문',
 '[시승기] 덩치에서 오는 안정감...2025 팰리세이드',
 'https://www.finomy.com/news/articleView.html?idxno=226448',
 date '2025-04-16','민성준','2.5T 가솔린 캘리그래피',
 'LX3 2025 팰리세이드 실제 공도 시승에서 차체 안정감·정숙성·전자제어 서스펜션·승차감과 공간을 평가한 독립 자료.'),

('현대','아반떼','CN7','모터그래프',
 '[시승기] 우리는 아반떼가 아닌 N을 사는 거야!',
 'https://www.motorgraph.com/news/articleView.html?idxno=28188',
 null,'권지용','아반떼 N',
 'CN7 기반 아반떼 N을 실제 시승해 고성능 파워트레인·섀시·브레이크·일상 활용성을 평가한 독립 전문 시승자료.'),

('아우디','e-tron GT','J1','연합뉴스',
 '[시승기] 전기차·스포츠카 다 잡았다…아우디 RS e-트론 GT',
 'https://www.yna.co.kr/view/AKR20230917010500003',
 date '2023-09-17','김보경','RS e-tron GT',
 'J1 RS e-tron GT를 독일·오스트리아·이탈리아 약 750km에서 직접 주행하며 고속 안정성·코너링·주행거리·승차감을 평가한 독립 시승자료.')
)
insert into public.external_review_sources(
 generation_id,source_type,source_name,title,canonical_url,published_date,observed_date,
 author_label,powertrain_hint,summary,source_confidence,approval_status,dedupe_status,
 owner_claimed,owner_verified,owner_score_eligible,value_score_eligible)
select g.id,'expert_road_test',s.source_name,s.title,s.url,s.published_date,date '2026-09-27',
 s.author_label,s.powertrain,s.summary,'B','approved_reference','unique',false,false,false,false
from src s
join public.manufacturers mf on mf.name=s.brand
join public.car_models cm on cm.manufacturer_id=mf.id and cm.name=s.model
join public.generations g on g.car_model_id=cm.id and g.generation_code=s.generation_code
on conflict(canonical_url) do update set
 generation_id=excluded.generation_id,
 source_type='expert_road_test',
 source_name=excluded.source_name,
 title=excluded.title,
 published_date=excluded.published_date,
 observed_date=excluded.observed_date,
 author_label=excluded.author_label,
 powertrain_hint=excluded.powertrain_hint,
 summary=excluded.summary,
 source_confidence='B',
 approval_status='approved_reference',
 dedupe_status='unique',
 owner_score_eligible=false,
 value_score_eligible=false,
 updated_at=now();

commit;
