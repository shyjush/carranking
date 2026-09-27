begin;

-- Tesla Model S/X are retained as historical 2021+ generations but are no longer current-production models.
update public.generations g
set current=false,
    end_year=case when g.end_year is null or g.end_year>2026 then 2026 else g.end_year end
from public.car_models cm, public.manufacturers mf
where g.car_model_id=cm.id
  and cm.manufacturer_id=mf.id
  and mf.name='테슬라'
  and cm.name in ('Model S','Model X')
  and g.current=true;

insert into public.source_records(entity_type,entity_id,source_url,confidence,verified_at,note)
select 'generation',g.id,
       case when cm.name='Model S' then 'https://www.tesla.com/models' else 'https://www.tesla.com/modelx' end,
       'A',date '2026-09-27',
       'Tesla 공식 차량 페이지가 해당 모델을 더 이상 생산하지 않는다고 명시. 기존 2021+ 세대는 과거 세대로 보존.'
from public.generations g
join public.car_models cm on cm.id=g.car_model_id
join public.manufacturers mf on mf.id=cm.manufacturer_id
where mf.name='테슬라' and cm.name in ('Model S','Model X')
and not exists(
  select 1 from public.source_records s
  where s.entity_type='generation' and s.entity_id=g.id
    and s.source_url=case when cm.name='Model S' then 'https://www.tesla.com/models' else 'https://www.tesla.com/modelx' end
);

with src(brand,model,generation_code,source_type,source_name,title,url,published_date,author_label,powertrain,summary,confidence) as (
values
('아우디','A3','8Y','expert_road_test','더아이오토','[시승기] 다이내믹함을 갖춘 소형 세단, 아우디 A3 40 TFSI 콰트로','https://www.theiauto.com/news/27647',date '2026-06-24','한창희 편집장','40 TFSI quattro','8Y A3 부분변경 40 TFSI 콰트로 실제 시승 평가 자료.','B'),
('아우디','A7','4K','expert_road_test','오토뷰','[시승기] 아우디 A7 55 TFSI quattro / 오토뷰 2020 4K','https://www.youtube.com/watch?v=QT7NA_x9E3w',date '2020-09-05','오토뷰 로드테스트팀','55 TFSI quattro','4K 2세대 A7 전문 계측 로드테스트. 가속·제동·무게 배분·정숙성 데이터를 포함한다.','A')
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
