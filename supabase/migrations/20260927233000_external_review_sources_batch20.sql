begin;

-- Q3 source-of-truth: 3rd generation officially launched in Korea in 2026.
with m as (
  select cm.id from public.car_models cm
  join public.manufacturers mf on mf.id=cm.manufacturer_id
  where mf.name='아우디' and cm.name='Q3'
)
update public.generations
set current=false, end_year=case when end_year is null or end_year>2026 then 2026 else end_year end
where car_model_id in (select id from m) and generation_code='F3' and current=true;

insert into public.generations(car_model_id,name,generation_code,start_year,end_year,current)
select cm.id,'3세대','FJ',2025,null,true
from public.car_models cm join public.manufacturers mf on mf.id=cm.manufacturer_id
where mf.name='아우디' and cm.name='Q3'
on conflict(car_model_id,name) do update
set generation_code='FJ',start_year=2025,end_year=null,current=true;

-- Tiguan AD1 is no longer sold in Korea; do not fabricate a successor before official Korean launch.
with m as (
  select cm.id from public.car_models cm
  join public.manufacturers mf on mf.id=cm.manufacturer_id
  where mf.name='폭스바겐' and cm.name='티구안'
)
update public.generations
set current=false, end_year=case when end_year is null or end_year>2025 then 2025 else end_year end
where car_model_id in (select id from m) and generation_code='AD1' and current=true;

-- Expedition source-of-truth: fifth generation replaced the prior U553 generation.
with m as (
  select cm.id from public.car_models cm
  join public.manufacturers mf on mf.id=cm.manufacturer_id
  where mf.name='포드' and cm.name='익스페디션'
)
update public.generations
set current=false, end_year=case when end_year is null or end_year>2025 then 2025 else end_year end
where car_model_id in (select id from m) and generation_code='U553' and current=true;

insert into public.generations(car_model_id,name,generation_code,start_year,end_year,current)
select cm.id,'5세대',null,2025,null,true
from public.car_models cm join public.manufacturers mf on mf.id=cm.manufacturer_id
where mf.name='포드' and cm.name='익스페디션'
on conflict(car_model_id,name) do update
set start_year=2025,end_year=null,current=true;

-- Generation evidence (idempotent)
insert into public.source_records(entity_type,entity_id,source_url,confidence,verified_at,note)
select 'generation',g.id,'https://www.audi.co.kr/ko/aboutaudi/news_article/2026/202606/20260609/20260609','A',date '2026-09-27',
       '아우디코리아가 2026-06-09 국내 공식 출시한 3세대 Q3.'
from public.generations g join public.car_models cm on cm.id=g.car_model_id
join public.manufacturers mf on mf.id=cm.manufacturer_id
where mf.name='아우디' and cm.name='Q3' and g.name='3세대'
and not exists(select 1 from public.source_records s where s.entity_type='generation' and s.entity_id=g.id and s.source_url='https://www.audi.co.kr/ko/aboutaudi/news_article/2026/202606/20260609/20260609');

insert into public.source_records(entity_type,entity_id,source_url,confidence,verified_at,note)
select 'generation',g.id,'https://www.fromtheroad.ford.com/us/en/articles/2024/all-new-ford-expedition-fully-redesigned-for-families-with-big-l','A',date '2026-09-27',
       'Ford 공식 자료가 2025 Expedition을 5세대로 확인.'
from public.generations g join public.car_models cm on cm.id=g.car_model_id
join public.manufacturers mf on mf.id=cm.manufacturer_id
where mf.name='포드' and cm.name='익스페디션' and g.name='5세대'
and not exists(select 1 from public.source_records s where s.entity_type='generation' and s.entity_id=g.id and s.source_url='https://www.fromtheroad.ford.com/us/en/articles/2024/all-new-ford-expedition-fully-redesigned-for-families-with-big-l');

with src(brand,model,match_key,match_mode,source_type,source_name,title,url,published_date,author_label,powertrain,summary,confidence) as (
values
('아우디','Q3','FJ','code','expert_road_test','탑라이더','[시승기] 아우디 Q3 블랙 에디션, Q5급 덩치와 옵션','https://www.top-rider.com/article/view/trd202608180001',date '2026-08-18','이한승','2.0 TFSI quattro','3세대 FJ Q3 실제 시승 평가 자료.','A'),
('메르세데스-벤츠','EQS','V297','code','expert_road_test','모터그래프','[시승기] 메르세데스-벤츠 EQS 450+ S가 부끄럽지 않은 전기차','https://www.motorgraph.com/news/articleView.html?idxno=29921',date '2022-05-09','신화섭','EQS 450+','V297 EQS 실제 시승 평가 자료.','A'),
('메르세데스-벤츠','G-클래스','W465','code','expert_road_test','모터그래프','전기로 깨운 야수의 본능 메르세데스-벤츠 G 580 EQ [시승기]','https://www.motorgraph.com/news/articleView.html?idxno=41257',null,null,'G 580 EQ','W465 현행 G클래스 전기 파생형 실제 오프로드 시승 평가 자료.','A'),
('메르세데스-벤츠','GLC','X254','code','expert_road_test','한국경제','SUV임을 잊게 만드는 안정감…주행 보조 기술도 진화','https://www.hankyung.com/article/2025102864951',date '2025-10-28',null,'GLC 300 4MATIC','X254 GLC 300 실제 시승 평가 자료.','B'),
('메르세데스-벤츠','GLS','X167','code','expert_road_test','뉴스핌','SUV의 S클래스…벤츠 GLS 450 나이트 에디션 시승기','https://www.newspim.com/news/view/20260410000731',date '2026-04-18','이찬우','GLS 450 4MATIC','X167 GLS 450 실제 시승 평가 자료.','B'),
('포드','익스플로러','7세대','name','expert_road_test','오토뷰','2026 포드 익스플로러 리뷰 [1274회]','https://www.autoview.co.kr/ko-kr/articles/100195',date '2026-05-16','오토뷰 로드테스트팀','3.0 EcoBoost Tremor','현행 익스플로러 전문 계측 로드테스트.','A'),
('테슬라','Model Y','주니퍼','name','expert_road_test','이코노미조선','테슬라 모델 Y 프리미엄 RWD 시승기','https://economychosun.com/site/data/html_dir/2026/05/18/2026051800023.html',date '2026-05-18','박진우','Premium RWD','Model Y 주니퍼 실차 장기 운행 기반 시승 평가 자료.','B'),
('포드','익스페디션','5세대','name','expert_road_test','Edmunds','2025 Ford Expedition Review','https://www.edmunds.com/ford/expedition/2025/',null,'Edmunds','5th generation','5세대 Expedition 독립 전문가 도로·테스트트랙 평가 자료.','B')
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
join public.generations g on g.car_model_id=cm.id
 and ((s.match_mode='code' and g.generation_code=s.match_key) or (s.match_mode='name' and g.name=s.match_key))
on conflict(canonical_url) do update set
 generation_id=excluded.generation_id,source_type=excluded.source_type,source_name=excluded.source_name,
 title=excluded.title,published_date=excluded.published_date,observed_date=excluded.observed_date,
 author_label=excluded.author_label,powertrain_hint=excluded.powertrain_hint,summary=excluded.summary,
 source_confidence=excluded.source_confidence,approval_status='approved_reference',dedupe_status='unique',
 owner_score_eligible=false,value_score_eligible=false,updated_at=now();

commit;
