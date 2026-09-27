begin;

-- Correct KGM Musso source-of-truth generation without deleting historical Q200.
with musso_model as (
  select cm.id
  from public.car_models cm
  join public.manufacturers mf on mf.id=cm.manufacturer_id
  where mf.name='KGM' and cm.name='무쏘'
)
update public.generations
set current=false,
    end_year=case when end_year is null or end_year>2025 then 2025 else end_year end
where car_model_id in (select id from musso_model)
  and generation_code='Q200'
  and current=true;

insert into public.generations(car_model_id,name,generation_code,start_year,end_year,current)
select cm.id,'신형 무쏘','Q300',2026,null,true
from public.car_models cm
join public.manufacturers mf on mf.id=cm.manufacturer_id
where mf.name='KGM' and cm.name='무쏘'
on conflict (car_model_id,name) do update
set generation_code='Q300',start_year=2026,end_year=null,current=true;

-- Evidence for the Q300 generation identity. Guarded to keep workflow idempotent.
insert into public.source_records(entity_type,entity_id,source_url,confidence,verified_at,note)
select
  'generation',
  g.id,
  'https://www.top-rider.com/article/view/trd202512260001',
  'A',
  date '2026-09-27',
  'KGM 차세대 픽업 공식 차명 무쏘, 프로젝트명 Q300 확인. 기존 Q200은 과거 세대로 보존.'
from public.generations g
join public.car_models cm on cm.id=g.car_model_id
join public.manufacturers mf on mf.id=cm.manufacturer_id
where mf.name='KGM' and cm.name='무쏘' and g.generation_code='Q300'
and not exists (
  select 1 from public.source_records s
  where s.entity_type='generation'
    and s.entity_id=g.id
    and s.source_url='https://www.top-rider.com/article/view/trd202512260001'
);

with src(
  brand, model, generation_code, source_type, source_name, title, canonical_url,
  published_date, observed_date, author_label, powertrain_hint, trim_hint,
  summary, source_confidence, approval_status, dedupe_status,
  owner_claimed, owner_verified
) as (
  values
    ('KGM','무쏘','Q300','expert_road_test','탑라이더',
     '[시승기] KGM 무쏘 가솔린, 완성도에서 디젤을 앞선다',
     'https://www.top-rider.com/article/view/trd202602230001',
     date '2026-02-23',date '2026-09-27','이한승','가솔린/2.2 디젤','신형 Q300',
     '신형 Q300 무쏘의 가솔린·디젤 파워트레인과 5링크/픽업 승차감, 고속 안정성 및 가격 구성을 실제 시승으로 평가한 전문자료다.',
     'A','approved_reference','unique',false,false),

    ('기아','타스만','TK1','expert_road_test','ZDNet Korea',
     '[타보고서] 상품성 꽉 잡은 기아 픽업 타스만…험로도 OK',
     'https://zdnet.co.kr/view/?no=20250404165826',
     date '2025-04-06',date '2026-09-27',null,'2.5T 가솔린',null,
     'TK1 타스만 미디어 시승에서 일반도로와 험로를 직접 주행한 평가. 전문 계측매체는 아니므로 B급 외부 시승 참고자료로 사용한다.',
     'B','approved_reference','unique',false,false)
)
insert into public.external_review_sources(
  generation_id, source_type, source_name, title, canonical_url,
  published_date, observed_date, author_label, powertrain_hint, trim_hint,
  summary, source_confidence, approval_status, dedupe_status,
  owner_claimed, owner_verified, owner_score_eligible, value_score_eligible
)
select
  g.id, s.source_type, s.source_name, s.title, s.canonical_url,
  s.published_date, s.observed_date, s.author_label, s.powertrain_hint, s.trim_hint,
  s.summary, s.source_confidence, s.approval_status, s.dedupe_status,
  s.owner_claimed, s.owner_verified, false, false
from src s
join public.manufacturers mf on mf.name=s.brand
join public.car_models cm on cm.manufacturer_id=mf.id and cm.name=s.model
join public.generations g on g.car_model_id=cm.id and g.generation_code=s.generation_code
on conflict (canonical_url) do update set
  generation_id=excluded.generation_id,
  source_type=excluded.source_type,
  source_name=excluded.source_name,
  title=excluded.title,
  published_date=excluded.published_date,
  observed_date=excluded.observed_date,
  author_label=excluded.author_label,
  powertrain_hint=excluded.powertrain_hint,
  trim_hint=excluded.trim_hint,
  summary=excluded.summary,
  source_confidence=excluded.source_confidence,
  approval_status=excluded.approval_status,
  dedupe_status=excluded.dedupe_status,
  owner_claimed=excluded.owner_claimed,
  owner_verified=excluded.owner_verified,
  owner_score_eligible=false,
  value_score_eligible=false,
  updated_at=now();

commit;
