begin;

with src(
  brand, model, generation_code, source_type, source_name, title, canonical_url,
  published_date, observed_date, author_label, powertrain_hint, trim_hint,
  summary, source_confidence, approval_status, dedupe_status,
  owner_claimed, owner_verified
) as (
  values
    ('기아','니로','SG2','expert_road_test','뉴시스',
     '[시승기] 기아 2세대 니로, 디자인·연비, 다 잡았네',
     'https://www.newsis.com/view/NISX20220204_0001747102',
     date '2022-02-06',date '2026-09-27','박주연','1.6 하이브리드','2세대 SG2',
     '2세대 SG2 니로 미디어 시승회에서 약 120km를 실제 주행하며 공간·주행 안정성·연비와 상품성을 평가한 기사다. 전문 계측매체는 아니므로 B로 분류한다.',
     'B','approved_reference','unique',false,false),

    ('현대','베뉴','QX','expert_road_test','연합뉴스',
     '[시승기] 엔트리 SUV 베뉴, 다부진 외모에 무난한 주행감',
     'https://www.yna.co.kr/view/AKR20190712032000003',
     date '2019-07-12',date '2026-09-27',null,'1.6 가솔린 IVT','QX',
     'QX 베뉴 출시 시점 실제 시승 기사. 실내 실용성·1.6 가솔린 IVT 파워트레인·주행감 등을 평가하며, 전문 계측자료는 아니므로 B로 분류한다.',
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
