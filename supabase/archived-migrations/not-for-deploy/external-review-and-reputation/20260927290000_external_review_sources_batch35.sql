begin;

insert into public.source_records(entity_type,entity_id,source_url,confidence,verified_at,note)
select 'generation',g.id,
       'https://www.autoview.co.kr/ko-kr/articles/67909',
       'A',date '2026-09-27',
       'Q200 과거 픽업 계열은 당시 렉스턴 스포츠/칸 명칭으로 판매. 현행 Q300 무쏘와 구분해 과거 계보 자료로 보존.'
from public.generations g
join public.car_models cm on cm.id=g.car_model_id
join public.manufacturers mf on mf.id=cm.manufacturer_id
where mf.name='KGM' and cm.name='무쏘' and g.generation_code='Q200'
and not exists(select 1 from public.source_records s where s.entity_type='generation' and s.entity_id=g.id and s.source_url='https://www.autoview.co.kr/ko-kr/articles/67909');

with src(brand,model,generation_code,title,url,published_date,author_label,powertrain,summary) as (
values
('KGM','무쏘','Q200','[시승기] 쌍용 렉스턴 스포츠 칸','https://www.autoview.co.kr/ko-kr/articles/67909',null,'오토뷰 로드테스트팀','2.2 디젤 픽업','Q200 계열 렉스턴 스포츠 칸의 실제 주행·승차감·적재·연비를 평가한 전문 시승자료. 현재 Q300 무쏘와는 분리된 과거 계보 근거.'),
('기아','카니발','VQ','[시승기] 기아, 뉴 카니발 R 2.2 디젤','https://www.autoview.co.kr/ko-kr/articles/46184',date '2012-10-29','오토뷰 로드테스트팀','2.2 디젤','VQ 2세대 카니발 후기형의 실제 주행·공간·승차감을 평가한 전문 로드테스트.')
)
insert into public.external_review_sources(
 generation_id,source_type,source_name,title,canonical_url,published_date,observed_date,
 author_label,powertrain_hint,summary,source_confidence,approval_status,dedupe_status,
 owner_claimed,owner_verified,owner_score_eligible,value_score_eligible)
select g.id,'expert_road_test','오토뷰',s.title,s.url,s.published_date,date '2026-09-27',
 s.author_label,s.powertrain,s.summary,'A','approved_reference','unique',false,false,false,false
from src s
join public.manufacturers mf on mf.name=s.brand
join public.car_models cm on cm.manufacturer_id=mf.id and cm.name=s.model
join public.generations g on g.car_model_id=cm.id and g.generation_code=s.generation_code
on conflict(canonical_url) do update set
 generation_id=excluded.generation_id,source_type='expert_road_test',source_name='오토뷰',
 title=excluded.title,published_date=excluded.published_date,observed_date=excluded.observed_date,
 author_label=excluded.author_label,powertrain_hint=excluded.powertrain_hint,summary=excluded.summary,
 source_confidence='A',approval_status='approved_reference',dedupe_status='unique',
 owner_score_eligible=false,value_score_eligible=false,updated_at=now();

commit;
