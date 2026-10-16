begin;
with src(brand,model,generation_code,source_type,source_name,title,url,published_date,author_label,powertrain,summary,confidence) as (
values
('랜드로버','레인지로버 스포츠','L461','expert_road_test','오토뷰','[시승기] 랜드로버, 3세대 레인지로버 스포츠','https://www.autoview.co.kr/ko-kr/articles/79033',date '2023-01-27','오토뷰 로드테스트팀','P360','L461 3세대 레인지로버 스포츠 전문 시승자료.','A'),
('볼보','S60','SPA','expert_road_test','탑라이더','[시승기] 볼보 S60 부분변경, 정숙성과 승차감 업그레이드','https://www.top-rider.com/article/view/trd202210100001',date '2022-10-10','이한승','B5','SPA S60 부분변경 실제 시승 평가 자료.','A'),
('아우디','Q8','4M8','expert_road_test','탑라이더','[시승기] 아우디 600마력 모음, 슈퍼카 R8부터 RS Q8까지','https://www.top-rider.com/article/view/trd202106080001',date '2021-06-08','이한승','RS Q8','4M8 Q8 세대의 고성능 RS Q8 서킷 및 도로 시승자료.','A'),
('아우디','A4','B9','expert_road_test','오토뷰','[시승기] 아우디, A4 45 TFSI 콰트로','https://www.autoview.co.kr/ko-kr/articles/59634',date '2016-05-30','오토뷰 로드테스트팀','45 TFSI quattro','B9 A4 전문 계측 시승자료.','A'),
('아우디','e-tron GT','J1','expert_road_test','모터그래프','[시승기] 아우디 RS e-트론 GT 아우디의 과거와 현재, 그리고 미래','https://www.motorgraph.com/news/articleView.html?idxno=31206',date '2022-12-16','권지용','RS e-tron GT','J1 e-tron GT 실제 시승 평가 자료.','A'),
('렉서스','RZ','EB10','expert_commentary','오토뷰','[렉서스 RZ] 답변 드립니다.','https://www.autoview.co.kr/ko-kr/boards/1/71711',date '2025-02-10','김기태 PD','RZ','EB10 RZ의 실제 주행 경험과 완성도에 대한 전문가 코멘트. 정식 리뷰가 아니므로 B.','B')
)
insert into public.external_review_sources(
 generation_id,source_type,source_name,title,canonical_url,published_date,observed_date,
 author_label,powertrain_hint,summary,source_confidence,approval_status,dedupe_status,
 owner_claimed,owner_verified,owner_score_eligible,value_score_eligible)
select g.id,s.source_type,s.source_name,s.title,s.url,s.published_date,date '2026-09-27',
 s.author_label,s.powertrain,s.summary,s.confidence,'approved_reference','unique',false,false,false,false
from src s
join public.manufacturers mf on mf.name=s.brand
join public.car_models cm on cm.manufacturer_id=mf.id and cm.name=s.model
join public.generations g on g.car_model_id=cm.id and g.generation_code=s.generation_code
on conflict(canonical_url) do update set
 generation_id=excluded.generation_id,source_type=excluded.source_type,source_name=excluded.source_name,
 title=excluded.title,published_date=excluded.published_date,observed_date=excluded.observed_date,
 author_label=excluded.author_label,powertrain_hint=excluded.powertrain_hint,summary=excluded.summary,
 source_confidence=excluded.source_confidence,approval_status='approved_reference',dedupe_status='unique',
 owner_score_eligible=false,value_score_eligible=false,updated_at=now();
commit;
