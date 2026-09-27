begin;
with src(brand,model,generation_code,source_type,source_name,title,url,published_date,author_label,powertrain,summary,confidence) as (
values
('메르세데스-벤츠','C-클래스','W206','expert_road_test','탑라이더','[시승기] 벤츠 신형 C클래스, 작은 고급차에 대한 정답','https://www.top-rider.com/article/view/trd202204070001',date '2022-04-07','이한승','C300 / C200 4MATIC','W206 C클래스 실제 시승 평가 자료.','A'),
('메르세데스-벤츠','S-클래스','W223','expert_road_test','오토뷰','2027 벤츠 S-클래스 페이스리프트 리뷰 [1299회]','https://www.autoview.co.kr/ko-kr/articles/101817',date '2026-09-19','오토뷰 로드테스트팀','S580 4MATIC','W223 부분변경 전문 계측 로드테스트.','A'),
('메르세데스-벤츠','GLE','V167','expert_road_test','오토뷰','메르세데스-벤츠 GLE 450 4매틱 쿠페 리뷰 [1256회]','https://www.autoview.co.kr/ko-kr/articles/98985',date '2026-02-04','오토뷰 로드테스트팀','GLE 450 4MATIC','V167 GLE 전문 계측 로드테스트.','A'),
('아우디','A6','C8','expert_road_test','오토뷰','아우디 A6 45 TFSI 콰트로 리뷰 [1280회]','https://www.autoview.co.kr/ko-kr/articles/100549',date '2026-06-13','오토뷰 로드테스트팀','45 TFSI quattro','C8 A6 전문 계측 로드테스트.','A'),
('아우디','Q5','FY','expert_road_test','오토뷰','아우디 Q5 40 TDI 콰트로 리뷰 [1225회]','https://www.autoview.co.kr/ko-kr/articles/97238',date '2025-09-20','오토뷰 로드테스트팀','40 TDI quattro','FY Q5 전문 계측 로드테스트.','A'),
('테슬라','Model 3','하이랜드','expert_commentary','오토뷰','토요타 프리우스HEV & 쏘나타 HEV & 모델3 답변','https://www.autoview.co.kr/ko-kr/boards/2/77099',date '2026-02-26','김기태 PD','RWD 하이랜드','Model 3 하이랜드의 승차감·ADAS·주행 경험에 대한 전문가 코멘트. 정식 계측 리뷰가 아니므로 B 참고자료.','B'),
('볼보','EX30','1세대','expert_commentary','오토뷰','폴스타4 & 볼보 EX30 & 테슬라 모델3 답변','https://www.autoview.co.kr/ko-kr/boards/2/79049',date '2026-07-19','김기태 PD','전기','EX30의 정숙성·시트·주행질감과 공간 한계에 대한 전문가 코멘트. B 참고자료.','B')
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
join public.generations g on g.car_model_id=cm.id and coalesce(g.generation_code,g.name)=s.generation_code
on conflict(canonical_url) do update set
 generation_id=excluded.generation_id,source_type=excluded.source_type,source_name=excluded.source_name,
 title=excluded.title,published_date=excluded.published_date,observed_date=excluded.observed_date,
 author_label=excluded.author_label,powertrain_hint=excluded.powertrain_hint,summary=excluded.summary,
 source_confidence=excluded.source_confidence,approval_status='approved_reference',dedupe_status='unique',
 owner_score_eligible=false,value_score_eligible=false,updated_at=now();
commit;
