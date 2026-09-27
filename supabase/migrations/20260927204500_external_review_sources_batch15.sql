begin;
with src(brand,model,generation_code,source_type,source_name,title,url,published_date,author_label,powertrain,summary,confidence) as (
values
('폭스바겐','골프','MK8','expert_road_test','탑라이더','[시승기] 폭스바겐 8세대 골프, 즐겁고 경제적인 매력쟁이','https://www.top-rider.com/article/view/trd202201060001',date '2022-01-06','이한승','2.0 TDI','MK8 골프 실제 시승 평가 자료.','A'),
('폭스바겐','제타','A7','expert_road_test','탑라이더','[시승기] 폭스바겐 제타 부분변경, 입문형 수입차로 제격','https://www.top-rider.com/article/view/trd202212120001',date '2022-12-12','이한승','1.5 TSI','A7 제타 부분변경 실제 시승 평가 자료.','A'),
('포드','레인저','P703','expert_road_test','탑라이더','[시승기] 포드 레인저 랩터, 온로드에서도 인상적 퍼포먼스','https://www.top-rider.com/article/view/trd202307050001',date '2023-07-05','이한승','2.0 바이터보 디젤','P703 신형 레인저 랩터 실제 온로드·오프로드 시승자료.','A'),
('포드','브롱코','U725','expert_road_test','탑라이더','[시승기] 포드 브롱코, 오프로드 주행했는데 허리가 안 아프다','https://www.top-rider.com/article/view/trd202204240001',date '2022-04-24','김한솔','2.7 V6 에코부스트','U725 브롱코 실제 오프로드 시승 평가 자료.','A'),
('포르쉐','파나메라','976','expert_road_test','오토뷰','[시승기] 2024 포르쉐 파나메라 4','https://www.autoview.co.kr/ko-kr/articles/92023',date '2024-07-01','전인호 기자','파나메라 4','976 3세대 파나메라 전문 계측 시승자료.','A'),
('폭스바겐','투아렉','CR','expert_commentary','오토뷰','랜드로버 디펜더 & 폭스바겐 투아렉 답변','https://www.autoview.co.kr/ko-kr/boards/2/79526',date '2026-09-13','김기태 PD','현행 투아렉','CR 투아렉의 고속안정성·승차감 특성에 대한 최신 전문가 비교 코멘트.','B')
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
