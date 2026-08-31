begin;

-- Public owner-review MVP: allow a browser visitor to submit one rating/review per vehicle.
-- A future authenticated account can coexist with these anonymous visitor rows.
alter table public.ratings alter column user_id drop not null;
alter table public.reviews alter column user_id drop not null;
alter table public.ratings add column if not exists visitor_id text;
alter table public.reviews add column if not exists visitor_id text;

alter table public.ratings drop constraint if exists ratings_identity_check;
alter table public.ratings add constraint ratings_identity_check check (user_id is not null or visitor_id is not null);
alter table public.reviews drop constraint if exists reviews_identity_check;
alter table public.reviews add constraint reviews_identity_check check (user_id is not null or visitor_id is not null);

create unique index if not exists uq_ratings_visitor_generation
  on public.ratings(visitor_id,generation_id) where visitor_id is not null;
create unique index if not exists uq_reviews_visitor_generation
  on public.reviews(visitor_id,generation_id) where visitor_id is not null;

grant select, insert on public.ratings, public.reviews to anon;
grant select, insert, update, delete on public.ratings, public.reviews to authenticated;

drop policy if exists "ratings anon insert" on public.ratings;
create policy "ratings anon insert" on public.ratings for insert to anon
  with check (user_id is null and visitor_id is not null and length(visitor_id) between 16 and 100);

drop policy if exists "reviews anon insert" on public.reviews;
create policy "reviews anon insert" on public.reviews for insert to anon
  with check (
    user_id is null and visitor_id is not null and length(visitor_id) between 16 and 100
    and status='published' and length(body) between 10 and 2000
    and (title is null or length(title) <= 100)
  );

create or replace view public.web_review_feed
with (security_invoker = true) as
select r.id, r.generation_id, r.title, r.body, r.created_at,
       coalesce(p.display_name,'익명 오너') display_name
from public.reviews r
left join public.profiles p on p.user_id=r.user_id
where r.status='published';

grant select on public.web_rating_summary, public.web_review_feed to anon, authenticated;

commit;
