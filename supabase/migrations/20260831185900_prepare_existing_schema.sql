-- Make the first managed migration safe to run after the schema was created manually.
-- Policies are dropped here and recreated by 20260831190000_initial_schema.sql.

begin;

drop policy if exists "public read manufacturers" on public.manufacturers;
drop policy if exists "public read car_models" on public.car_models;
drop policy if exists "public read generations" on public.generations;
drop policy if exists "public read powertrains" on public.powertrains;
drop policy if exists "public read trims" on public.trims;
drop policy if exists "public read vehicle_specs" on public.vehicle_specs;
drop policy if exists "public read market_snapshots" on public.market_snapshots;
drop policy if exists "public read depreciation_metrics" on public.depreciation_metrics;
drop policy if exists "public read known_issues" on public.known_issues;
drop policy if exists "public read source_records" on public.source_records;
drop policy if exists "profiles select own" on public.profiles;
drop policy if exists "profiles update own" on public.profiles;
drop policy if exists "ratings public read" on public.ratings;
drop policy if exists "ratings insert own" on public.ratings;
drop policy if exists "ratings update own" on public.ratings;
drop policy if exists "ratings delete own" on public.ratings;
drop policy if exists "reviews public published" on public.reviews;
drop policy if exists "reviews insert own" on public.reviews;
drop policy if exists "reviews update own" on public.reviews;
drop policy if exists "reviews delete own" on public.reviews;

commit;
