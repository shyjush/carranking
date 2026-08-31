begin;

create extension if not exists pgcrypto;

create table if not exists public.manufacturers (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  slug text not null unique,
  country text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.car_models (
  id uuid primary key default gen_random_uuid(),
  manufacturer_id uuid not null references public.manufacturers(id) on delete cascade,
  name text not null,
  slug text not null,
  category text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (manufacturer_id, name)
);

create table if not exists public.generations (
  id uuid primary key default gen_random_uuid(),
  car_model_id uuid not null references public.car_models(id) on delete cascade,
  name text not null,
  generation_code text,
  start_year int,
  end_year int,
  current boolean not null default false,
  created_at timestamptz not null default now(),
  unique (car_model_id, name)
);

create table if not exists public.powertrains (
  id uuid primary key default gen_random_uuid(),
  generation_id uuid not null references public.generations(id) on delete cascade,
  name text not null,
  fuel_type text,
  displacement_cc int,
  max_power_ps numeric,
  max_torque_kgfm numeric,
  battery_kwh numeric,
  created_at timestamptz not null default now()
);

create table if not exists public.trims (
  id uuid primary key default gen_random_uuid(),
  powertrain_id uuid not null references public.powertrains(id) on delete cascade,
  model_year int,
  name text not null,
  price_krw bigint,
  price_before_tax_benefit_krw bigint,
  price_basis text,
  source_url text,
  verified_at date,
  created_at timestamptz not null default now()
);

create table if not exists public.vehicle_specs (
  id uuid primary key default gen_random_uuid(),
  generation_id uuid not null references public.generations(id) on delete cascade,
  powertrain_id uuid references public.powertrains(id) on delete set null,
  length_mm int,
  width_mm int,
  height_mm int,
  wheelbase_mm int,
  combined_efficiency text,
  source_url text,
  verified_at date,
  created_at timestamptz not null default now()
);

create table if not exists public.market_snapshots (
  id uuid primary key default gen_random_uuid(),
  generation_id uuid not null references public.generations(id) on delete cascade,
  model_year int not null,
  as_of_date date not null,
  listing_count int,
  avg_price_krw bigint,
  p10_price_krw bigint,
  p90_price_krw bigint,
  source_name text not null,
  source_url text,
  confidence text not null default 'C',
  note text,
  created_at timestamptz not null default now(),
  unique (generation_id, model_year, as_of_date, source_name)
);

create table if not exists public.depreciation_metrics (
  id uuid primary key default gen_random_uuid(),
  generation_id uuid not null references public.generations(id) on delete cascade,
  model_year int not null,
  original_price_krw bigint,
  used_price_krw bigint,
  retention_rate numeric generated always as
    (case when original_price_krw > 0 and used_price_krw is not null
      then used_price_krw::numeric / original_price_krw else null end) stored,
  depreciation_rate numeric generated always as
    (case when original_price_krw > 0 and used_price_krw is not null
      then 1 - used_price_krw::numeric / original_price_krw else null end) stored,
  as_of_date date,
  sample_size int,
  confidence text not null default 'C',
  note text,
  created_at timestamptz not null default now(),
  unique (generation_id, model_year, as_of_date)
);

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  role text not null default 'user' check (role in ('user','admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.ratings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  generation_id uuid not null references public.generations(id) on delete cascade,
  ride_comfort int check (ride_comfort between 1 and 10),
  quietness int check (quietness between 1 and 10),
  performance int check (performance between 1 and 10),
  fuel_efficiency int check (fuel_efficiency between 1 and 10),
  maintenance_cost int check (maintenance_cost between 1 and 10),
  reliability int check (reliability between 1 and 10),
  design int check (design between 1 and 10),
  convenience int check (convenience between 1 and 10),
  resale_value int check (resale_value between 1 and 10),
  repurchase_intent int check (repurchase_intent between 1 and 10),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, generation_id)
);

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  generation_id uuid not null references public.generations(id) on delete cascade,
  title text,
  body text not null,
  status text not null default 'published' check (status in ('draft','published','hidden')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.known_issues (
  id uuid primary key default gen_random_uuid(),
  generation_id uuid not null references public.generations(id) on delete cascade,
  title text not null,
  severity text,
  description text,
  source_url text,
  verified_at date,
  created_at timestamptz not null default now()
);

create table if not exists public.source_records (
  id uuid primary key default gen_random_uuid(),
  entity_type text not null,
  entity_id uuid not null,
  source_url text not null,
  confidence text not null check (confidence in ('A','A-','B','B-','C')),
  verified_at date,
  note text,
  created_at timestamptz not null default now()
);

create index if not exists idx_models_manufacturer on public.car_models(manufacturer_id);
create index if not exists idx_generations_model on public.generations(car_model_id);
create index if not exists idx_generations_code on public.generations(generation_code);
create index if not exists idx_market_rank on public.market_snapshots(model_year, as_of_date desc, avg_price_krw desc);
create index if not exists idx_depr_rank on public.depreciation_metrics(retention_rate desc);
create index if not exists idx_ratings_generation on public.ratings(generation_id);
create index if not exists idx_reviews_generation_status on public.reviews(generation_id, status);

alter table public.manufacturers enable row level security;
alter table public.car_models enable row level security;
alter table public.generations enable row level security;
alter table public.powertrains enable row level security;
alter table public.trims enable row level security;
alter table public.vehicle_specs enable row level security;
alter table public.market_snapshots enable row level security;
alter table public.depreciation_metrics enable row level security;
alter table public.profiles enable row level security;
alter table public.ratings enable row level security;
alter table public.reviews enable row level security;
alter table public.known_issues enable row level security;
alter table public.source_records enable row level security;

revoke all on all tables in schema public from anon, authenticated;

grant select on public.manufacturers, public.car_models, public.generations, public.powertrains,
  public.trims, public.vehicle_specs, public.market_snapshots, public.depreciation_metrics,
  public.known_issues, public.source_records to anon, authenticated;

grant select, insert, update, delete on public.ratings, public.reviews to authenticated;
grant select, update on public.profiles to authenticated;

create policy "public read manufacturers" on public.manufacturers for select to anon, authenticated using (true);
create policy "public read car_models" on public.car_models for select to anon, authenticated using (true);
create policy "public read generations" on public.generations for select to anon, authenticated using (true);
create policy "public read powertrains" on public.powertrains for select to anon, authenticated using (true);
create policy "public read trims" on public.trims for select to anon, authenticated using (true);
create policy "public read vehicle_specs" on public.vehicle_specs for select to anon, authenticated using (true);
create policy "public read market_snapshots" on public.market_snapshots for select to anon, authenticated using (true);
create policy "public read depreciation_metrics" on public.depreciation_metrics for select to anon, authenticated using (true);
create policy "public read known_issues" on public.known_issues for select to anon, authenticated using (true);
create policy "public read source_records" on public.source_records for select to anon, authenticated using (true);

create policy "profiles select own" on public.profiles for select to authenticated using ((select auth.uid()) = user_id);
create policy "profiles update own" on public.profiles for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

create policy "ratings public read" on public.ratings for select to anon, authenticated using (true);
create policy "ratings insert own" on public.ratings for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "ratings update own" on public.ratings for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "ratings delete own" on public.ratings for delete to authenticated using ((select auth.uid()) = user_id);

create policy "reviews public published" on public.reviews for select to anon, authenticated using (status = 'published');
create policy "reviews insert own" on public.reviews for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "reviews update own" on public.reviews for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "reviews delete own" on public.reviews for delete to authenticated using ((select auth.uid()) = user_id);

create or replace view public.web_depreciation_ranking
with (security_invoker = true)
as
select
  dm.id,
  mf.name as brand,
  cm.name as model,
  g.name as generation,
  g.generation_code,
  dm.model_year,
  dm.original_price_krw,
  dm.used_price_krw,
  dm.retention_rate,
  dm.depreciation_rate,
  dm.sample_size,
  dm.as_of_date,
  dm.confidence
from public.depreciation_metrics dm
join public.generations g on g.id = dm.generation_id
join public.car_models cm on cm.id = g.car_model_id
join public.manufacturers mf on mf.id = cm.manufacturer_id
where dm.retention_rate is not null;

grant select on public.web_depreciation_ranking to anon, authenticated;

commit;
