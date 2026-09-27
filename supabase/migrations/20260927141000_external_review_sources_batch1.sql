begin;

-- CarRanking external evaluation/reference evidence.
-- This dataset is deliberately separated from owner ratings/reviews and value-retention inputs.
-- No source row in this table can affect owner ranking or value-retention ranking.

create table if not exists public.external_review_sources (
  id uuid primary key default gen_random_uuid(),
  generation_id uuid not null references public.generations(id) on delete cascade,
  source_type text not null check (source_type in ('expert_road_test','expert_commentary','owner_report_unverified')),
  source_name text not null,
  title text not null,
  canonical_url text not null unique check (canonical_url like 'https://%'),
  published_date date,
  observed_date date not null,
  author_label text,
  powertrain_hint text,
  trim_hint text,
  summary text not null,
  source_confidence text not null check (source_confidence in ('A','B','C')),
  approval_status text not null check (approval_status in ('approved_reference','hold','rejected')),
  dedupe_status text not null default 'unique' check (dedupe_status in ('unique','possible_duplicate','duplicate')),
  owner_claimed boolean not null default false,
  owner_verified boolean not null default false,
  owner_score_eligible boolean not null default false check (owner_score_eligible = false),
  value_score_eligible boolean not null default false check (value_score_eligible = false),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint external_review_owner_verify_guard check (not owner_verified or owner_claimed)
);

comment on table public.external_review_sources is
  'External professional evaluations and unverified owner-report references. Never feeds owner score or value-retention score.';
comment on column public.external_review_sources.source_confidence is
  'Confidence for external reference quality only; independent from value-retention A/B market-evidence qualification.';
comment on column public.external_review_sources.owner_report_unverified is null;

create index if not exists external_review_generation_idx
  on public.external_review_sources(generation_id, published_date desc);
create index if not exists external_review_status_idx
  on public.external_review_sources(approval_status, source_confidence, observed_date desc);

alter table public.external_review_sources enable row level security;

revoke all on public.external_review_sources from anon, authenticated;
grant select on public.external_review_sources to anon, authenticated;

drop policy if exists "external review approved public read" on public.external_review_sources;
create policy "external review approved public read"
on public.external_review_sources
for select
to anon, authenticated
using (
  approval_status = 'approved_reference'
  or exists (
    select 1
    from public.profiles p
    where p.user_id = (select auth.uid())
      and p.role = 'admin'
  )
);

with src(
  brand, model, generation_code, source_type, source_name, title, canonical_url,
  published_date, observed_date, author_label, powertrain_hint, trim_hint,
  summary, source_confidence, approval_status, dedupe_status,
  owner_claimed, owner_verified
) as (
  values
    ('제네시스','G80','RG3','expert_road_test','오토뷰',
     '제네시스 G80 블랙 3.5T AWD 리뷰 [1259회]',
     'https://www.autoview.co.kr/ko-kr/articles/99099',
     date '2026-02-17',date '2026-09-27','오토뷰 로드테스트팀','3.5T AWD','블랙',
     '전문 계측 기반 로드테스트. 가속·제동·중량·정숙성·가격과 주행 특성을 함께 다룬 외부 평가 근거다.',
     'A','approved_reference','unique',false,false),

    ('제네시스','GV80','JX1','expert_road_test','오토뷰',
     '제네시스 GV80 3.5T AWD 리뷰 [1244회]',
     'https://www.autoview.co.kr/ko-kr/articles/98473',
     date '2025-12-20',date '2026-09-27','오토뷰 로드테스트팀','3.5T AWD','5인승',
     '전문 계측 기반 로드테스트. 주행 안정성·인포테인먼트·ADAS와 저속 승차감·실주행 성능에 대한 장단점 평가를 포함한다.',
     'A','approved_reference','unique',false,false),

    ('제네시스','GV70','JK1','expert_road_test','오토뷰',
     '[시승기] 2024 제네시스 GV70 3.5T AWD',
     'https://www.autoview.co.kr/ko-kr/articles/92290',
     date '2024-07-25',date '2026-09-27','전인호 기자','3.5T AWD',null,
     '부분변경 GV70 전문 시승기. 인테리어·인터페이스·정숙성과 서스펜션·조작계·주행 안정성을 계측 및 주행 관점에서 평가한다.',
     'A','approved_reference','unique',false,false),

    ('기아','EV3','SV','expert_road_test','오토뷰',
     '기아 EV3 롱레인지 [1147회]',
     'https://www.autoview.co.kr/ko-kr/articles/92575',
     date '2024-08-26',date '2026-09-27','오토뷰 로드테스트팀','전기','롱레인지',
     'EV3 롱레인지 전문 로드테스트 원문을 SV 세대의 외부 평가 근거로 등록했다. 세부 평가는 원문 링크에서 확인한다.',
     'A','approved_reference','unique',false,false),

    ('기아','EV6','CV','expert_road_test','오토뷰',
     '기아 EV6 롱레인지 AWD [1150회]',
     'https://www.autoview.co.kr/ko-kr/articles/92805',
     date '2024-09-12',date '2026-09-27','오토뷰 로드테스트팀','전기 AWD','GT-라인 롱레인지',
     'EV6 롱레인지 AWD GT-라인 전문 로드테스트 원문을 CV 세대의 외부 평가 근거로 등록했다.',
     'A','approved_reference','unique',false,false),

    ('현대','싼타페','MX5','expert_road_test','모터그래프',
     '기아 쏘렌토 대신 현대 싼타페를 추천하는 이유 [시승기]',
     'https://www.motorgraph.com/news/articleView.html?idxno=33199',
     date '2024-01-13',date '2026-09-27','김선웅','1.6T 하이브리드',null,
     'MX5 하이브리드 전문 시승기. 공간·정숙성·편의 구성과 실제 주행 특성을 중심으로 쏘렌토와 비교 평가한다.',
     'A','approved_reference','unique',false,false),

    ('현대','그랜저','GN7','expert_road_test','모터그래프',
     '현대 그랜저 하이브리드 vs 토요타 캠리 하이브리드 [비교시승기]',
     'https://www.motorgraph.com/news/articleView.html?idxno=41440',
     date '2025-01-07',date '2026-09-27','김선웅','하이브리드',null,
     'GN7 하이브리드 비교시승. 공간·정숙성·승차감·가속과 실주행 연비를 직접 측정·비교한 전문 평가 근거다.',
     'A','approved_reference','unique',false,false),

    ('기아','쏘렌토','MQ4','expert_road_test','모터그래프',
     '‘엔진은 거들 뿐’ 기아차 쏘렌토 하이브리드, 아빠들의 ‘답정너’',
     'https://www.motorgraph.com/news/articleView.html?idxno=26223',
     null,date '2026-09-27','권지용','1.6T 하이브리드',null,
     'MQ4 하이브리드 전문 시승. 도심·고속도로 등 복수 주행환경에서 실제 연비와 가속·정숙성·패밀리카 활용성을 평가한다.',
     'A','approved_reference','unique',false,false),

    ('기아','K8','GL3','expert_commentary','오토뷰',
     '[기아 K8 3.5 로드테스트] 답변 드립니다.',
     'https://www.autoview.co.kr/ko-kr/boards/1/71297',
     date '2024-10-22',date '2026-09-27','김기태 PD','3.5 가솔린',null,
     '전문 로드테스트 제작진의 답변형 평가. K8의 전체 밸런스와 대형 휠 세팅에 대한 의견이지만 완결된 로드테스트 기사는 아니어서 B 참고자료로 분류했다.',
     'B','approved_reference','unique',false,false),

    ('제네시스','G80','RG3','owner_report_unverified','오토뷰',
     'G80 RG3 2021년식 5년 운용 사용자 글',
     'https://www.autoview.co.kr/ko-kr/boards/1/76961',
     date '2026-01-11',date '2026-09-27','palmydays','미상','2021년식',
     '작성자가 G80 RG3 2021년식을 약 5년 운용했다고 밝힌 사용자 경험 글. 실소유 인증은 CarRanking에서 확인되지 않아 오너평점에는 반영하지 않는다.',
     'C','hold','unique',true,false),

    ('기아','쏘렌토','MQ4','owner_report_unverified','오토뷰',
     '쏘렌토 하이브리드 초기형(MQ4) 운용 사용자 글',
     'https://www.autoview.co.kr/ko-kr/boards/2/75875',
     date '2025-04-28',date '2026-09-27','wingen','하이브리드','2022 프레스티지',
     '작성자가 2022년형 MQ4 쏘렌토 하이브리드 프레스티지를 운용한다고 밝힌 사용자 경험 글. 실소유 인증은 확인되지 않아 오너평점에는 반영하지 않는다.',
     'C','hold','unique',true,false),

    ('기아','EV6','CV','owner_report_unverified','오토뷰',
     'EV6 GT 2년 운용 사용자 글',
     'https://www.autoview.co.kr/ko-kr/boards/3/79493',
     date '2026-09-08',date '2026-09-27','fox905','전기 AWD','EV6 GT 페이스리프트 전',
     '작성자가 기아 인증중고차를 통해 EV6 GT를 구매해 약 2년 운용했다고 밝힌 사용자 경험 글. CarRanking 실소유 인증 전까지 참고 후보로만 보류한다.',
     'C','hold','unique',true,false)
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
join public.manufacturers mf on mf.name = s.brand
join public.car_models cm on cm.manufacturer_id = mf.id and cm.name = s.model
join public.generations g on g.car_model_id = cm.id and g.generation_code = s.generation_code
on conflict (canonical_url) do update set
  generation_id = excluded.generation_id,
  source_type = excluded.source_type,
  source_name = excluded.source_name,
  title = excluded.title,
  published_date = excluded.published_date,
  observed_date = excluded.observed_date,
  author_label = excluded.author_label,
  powertrain_hint = excluded.powertrain_hint,
  trim_hint = excluded.trim_hint,
  summary = excluded.summary,
  source_confidence = excluded.source_confidence,
  approval_status = excluded.approval_status,
  dedupe_status = excluded.dedupe_status,
  owner_claimed = excluded.owner_claimed,
  owner_verified = excluded.owner_verified,
  owner_score_eligible = false,
  value_score_eligible = false,
  updated_at = now();

create or replace view public.web_external_review_feed
with (security_invoker = true) as
select
  e.id,
  e.generation_id,
  mf.name as brand,
  cm.name as model,
  g.name as generation,
  g.generation_code,
  e.source_type,
  e.source_name,
  e.title,
  e.canonical_url as source_url,
  e.published_date,
  e.observed_date,
  e.author_label,
  e.powertrain_hint,
  e.trim_hint,
  e.summary,
  e.source_confidence,
  e.dedupe_status
from public.external_review_sources e
join public.generations g on g.id = e.generation_id
join public.car_models cm on cm.id = g.car_model_id
join public.manufacturers mf on mf.id = cm.manufacturer_id
where e.approval_status = 'approved_reference';

grant select on public.web_external_review_feed to anon, authenticated;

commit;
