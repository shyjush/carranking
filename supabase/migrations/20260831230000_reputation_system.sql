begin;

alter table public.profiles add column if not exists points integer not null default 0 check(points >= 0);
alter table public.profiles add column if not exists level integer not null default 1 check(level between 1 and 100);
alter table public.profiles add column if not exists review_count integer not null default 0 check(review_count >= 0);
alter table public.profiles add column if not exists verified_review_count integer not null default 0 check(verified_review_count >= 0);
alter table public.profiles add column if not exists helpful_received integer not null default 0 check(helpful_received >= 0);
alter table public.profiles add column if not exists bio text;

alter table public.reviews add column if not exists ownership_status text not null default '미인증' check(ownership_status in ('미인증','인증대기','인증완료','인증반려'));
alter table public.reviews add column if not exists model_year integer;
alter table public.reviews add column if not exists mileage_km integer check(mileage_km is null or mileage_km >= 0);
alter table public.reviews add column if not exists owned_months integer check(owned_months is null or owned_months >= 0);
alter table public.reviews add column if not exists helpful_count integer not null default 0 check(helpful_count >= 0);
alter table public.reviews add column if not exists photo_count integer not null default 0 check(photo_count >= 0);

create table if not exists public.review_helpful (
  review_id uuid not null references public.reviews(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(review_id,user_id)
);

create table if not exists public.ownership_verifications (
  verification_id uuid primary key default gen_random_uuid(),
  review_id uuid not null references public.reviews(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  verification_type text not null check(verification_type in ('차량등록증','보험','정비내역','기타')),
  status text not null default '대기' check(status in ('대기','승인','반려')),
  evidence_url text,
  admin_note text,
  created_at timestamptz not null default now(),
  reviewed_at timestamptz,
  unique(review_id,verification_type)
);

create table if not exists public.point_events (
  event_id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  source_type text not null check(source_type in ('review','verification','helpful','photo','admin')),
  source_id text not null,
  points integer not null check(points <> 0),
  reason text not null,
  created_at timestamptz not null default now(),
  unique(user_id,source_type,source_id,reason)
);

create table if not exists public.badges (
  badge_code text primary key,
  name text not null unique,
  description text not null,
  icon text,
  min_points integer not null default 0,
  min_reviews integer not null default 0,
  min_verified_reviews integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.user_badges (
  user_id uuid not null references auth.users(id) on delete cascade,
  badge_code text not null references public.badges(badge_code) on delete cascade,
  earned_at timestamptz not null default now(),
  primary key(user_id,badge_code)
);

insert into public.badges(badge_code,name,description,icon,min_points,min_reviews,min_verified_reviews) values
('first_review','첫 차 리뷰','첫 차량 리뷰 작성','✍️',0,1,0),
('owner_verified','실소유 인증','실소유 인증 리뷰 보유','✅',0,0,1),
('longterm_5','장기보유 리뷰어','검증 리뷰 5건 이상','🛣️',0,0,5),
('reviewer_20','자동차 리뷰어','리뷰 20건 이상','🏅',0,20,0),
('point_1000','CarRanking 마스터','누적 1,000포인트','👑',1000,0,0)
on conflict (badge_code) do nothing;

alter table public.review_helpful enable row level security;
alter table public.ownership_verifications enable row level security;
alter table public.point_events enable row level security;
alter table public.badges enable row level security;
alter table public.user_badges enable row level security;

create index if not exists review_helpful_user_idx on public.review_helpful(user_id);
create index if not exists ownership_verifications_user_idx on public.ownership_verifications(user_id);
create index if not exists point_events_user_created_idx on public.point_events(user_id,created_at desc);

commit;
