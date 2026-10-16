begin;
with src(brand,model,generation_code,source_name,title,url,published_date,author_label,powertrain,summary) as (
values
('기아','K3','BD','오토뷰','[시승기] 기아, K3 1.6','https://www.autoview.co.kr/ko-kr/articles/64401',date '2018-05-09','오토뷰 로드테스트팀','1.6 가솔린','BD 2세대 K3 전문 계측 로드테스트.'),
('기아','모닝','TA','오토뷰','[시승기] 기아, 뉴 모닝','https://www.autoview.co.kr/ko-kr/articles/40750',date '2011-03-21','오토뷰 로드테스트팀','1.0 가솔린','TA 2세대 모닝 전문 로드테스트.'),
('기아','스포티지','QL','오토뷰','[시승기] 기아, 스포티지 R2.0 E-VGT','https://www.autoview.co.kr/ko-kr/articles/58530',date '2016-05-04','오토뷰 로드테스트팀','2.0 디젤','QL 4세대 스포티지 전문 계측 로드테스트.'),
('기아','스포티지','SL','오토뷰','[시승기] 기아 스포티지R 2.0 2WD','https://www.autoview.co.kr/ko-kr/articles/39136',date '2010-09-06','오토뷰 로드테스트팀','2.0 디젤 2WD','SL 3세대 스포티지 전문 계측 로드테스트.'),
('기아','쏘렌토','XM','오토뷰','[시승기] 기아 쏘렌토 R 2.0 디젤','https://www.autoview.co.kr/ko-kr/articles/34924',date '2010-01-04','오토뷰 로드테스트팀','2.0 디젤','XM 2세대 쏘렌토 전문 계측 로드테스트.'),
('기아','카니발','YP','오토뷰','[시승기] 기아, 카니발 R2.2 E-VGT 9인승','https://www.autoview.co.kr/ko-kr/articles/53906',date '2014-11-20','오토뷰 로드테스트팀','2.2 디젤 9인승','YP 3세대 카니발 전문 로드테스트.'),
('기아','K7','YG','오토뷰','[시승기] 기아, K7 3.3 GDi','https://www.autoview.co.kr/ko-kr/articles/58906',date '2016-06-21','오토뷰 로드테스트팀','3.3 GDi','YG 2세대 K7 전문 계측 로드테스트.'),
('기아','K7','VG','오토뷰','[시승기] 기아 K7 3.5 (VG350)','https://www.autoview.co.kr/ko-kr/articles/35622',date '2010-02-04','오토뷰 로드테스트팀','3.5 가솔린','VG 1세대 K7 전문 계측 로드테스트.'),
('제네시스','G90','HI','오토뷰','[시승기] 제네시스, EQ900 3.3 T-GDi AWD','https://www.autoview.co.kr/ko-kr/articles/58503',date '2016-05-02','오토뷰 로드테스트팀','3.3T AWD','HI/EQ900 계열 G90 전문 계측 로드테스트.')
)
insert into public.external_review_sources(
 generation_id,source_type,source_name,title,canonical_url,published_date,observed_date,
 author_label,powertrain_hint,summary,source_confidence,approval_status,dedupe_status,
 owner_claimed,owner_verified,owner_score_eligible,value_score_eligible)
select g.id,'expert_road_test',s.source_name,s.title,s.url,s.published_date,date '2026-09-27',
 s.author_label,s.powertrain,s.summary,'A','approved_reference','unique',false,false,false,false
from src s
join public.manufacturers mf on mf.name=s.brand
join public.car_models cm on cm.manufacturer_id=mf.id and cm.name=s.model
join public.generations g on g.car_model_id=cm.id and g.generation_code=s.generation_code
on conflict(canonical_url) do update set
 generation_id=excluded.generation_id,source_type='expert_road_test',source_name=excluded.source_name,
 title=excluded.title,published_date=excluded.published_date,observed_date=excluded.observed_date,
 author_label=excluded.author_label,powertrain_hint=excluded.powertrain_hint,summary=excluded.summary,
 source_confidence='A',approval_status='approved_reference',dedupe_status='unique',
 owner_score_eligible=false,value_score_eligible=false,updated_at=now();
commit;
