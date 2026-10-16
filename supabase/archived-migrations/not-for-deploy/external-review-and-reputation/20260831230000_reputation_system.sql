begin;

create schema if not exists private;

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

create unique index if not exists reviews_one_per_user_generation
  on public.reviews(user_id,generation_id);

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
('first_review','첫 차 리뷰','첫 차량 오너리뷰 작성','✍️',0,1,0),
('owner_verified','실소유 인증','실소유 인증 리뷰 보유','✅',0,0,1),
('reviewer_5','오너 리뷰어','차량 리뷰 5건 이상','🚘',0,5,0),
('trusted_owner','신뢰 오너','실소유 인증 리뷰 3건 이상','🏅',0,0,3),
('longterm_owner','장기보유 오너','인증 차량을 36개월 이상 보유','🛣️',0,0,0),
('high_mileage','10만km 오너','인증 차량 주행거리 10만km 이상','🧭',0,0,0),
('point_1000','CarRanking 마스터','누적 1,000포인트','👑',1000,0,0)
on conflict (badge_code) do update set
 name=excluded.name,description=excluded.description,icon=excluded.icon,
 min_points=excluded.min_points,min_reviews=excluded.min_reviews,
 min_verified_reviews=excluded.min_verified_reviews,is_active=true;

create index if not exists review_helpful_user_idx on public.review_helpful(user_id);
create index if not exists ownership_verifications_user_idx on public.ownership_verifications(user_id);
create index if not exists point_events_user_created_idx on public.point_events(user_id,created_at desc);

alter table public.review_helpful enable row level security;
alter table public.ownership_verifications enable row level security;
alter table public.point_events enable row level security;
alter table public.badges enable row level security;
alter table public.user_badges enable row level security;

-- role 자체 승격 방지: 일반 회원은 display_name만 수정 가능
revoke update on public.profiles from authenticated;
grant select on public.profiles to authenticated;
grant update(display_name) on public.profiles to authenticated;
grant insert(user_id,display_name) on public.profiles to authenticated;

drop policy if exists "profiles insert own" on public.profiles;
create policy "profiles insert own" on public.profiles for insert to authenticated
with check ((select auth.uid()) = user_id and role = 'user');

-- reputation tables grants/RLS
grant select on public.badges,public.user_badges,public.review_helpful to anon,authenticated;
grant insert,delete on public.review_helpful to authenticated;
grant select on public.point_events to authenticated;
grant select,insert on public.ownership_verifications to authenticated;
revoke insert,update,delete on public.point_events,public.badges,public.user_badges from anon,authenticated;

drop policy if exists "helpful public read" on public.review_helpful;
create policy "helpful public read" on public.review_helpful for select to anon,authenticated using(true);
drop policy if exists "helpful own insert" on public.review_helpful;
create policy "helpful own insert" on public.review_helpful for insert to authenticated
with check (
  (select auth.uid()) = user_id
  and exists(select 1 from public.reviews r where r.id=review_helpful.review_id and r.user_id<>(select auth.uid()))
);
drop policy if exists "helpful own delete" on public.review_helpful;
create policy "helpful own delete" on public.review_helpful for delete to authenticated
using((select auth.uid())=user_id);

drop policy if exists "points own read" on public.point_events;
create policy "points own read" on public.point_events for select to authenticated
using((select auth.uid())=user_id);

drop policy if exists "badges public read" on public.badges;
create policy "badges public read" on public.badges for select to anon,authenticated using(is_active=true);
drop policy if exists "user badges public read" on public.user_badges;
create policy "user badges public read" on public.user_badges for select to anon,authenticated using(true);

drop policy if exists "verification own read" on public.ownership_verifications;
create policy "verification own read" on public.ownership_verifications for select to authenticated
using((select auth.uid())=user_id or exists(select 1 from public.profiles p where p.user_id=(select auth.uid()) and p.role='admin'));
drop policy if exists "verification own insert" on public.ownership_verifications;
create policy "verification own insert" on public.ownership_verifications for insert to authenticated
with check((select auth.uid())=user_id and exists(select 1 from public.reviews r where r.id=review_id and r.user_id=(select auth.uid())));
drop policy if exists "verification admin update" on public.ownership_verifications;
create policy "verification admin update" on public.ownership_verifications for update to authenticated
using(exists(select 1 from public.profiles p where p.user_id=(select auth.uid()) and p.role='admin'))
with check(exists(select 1 from public.profiles p where p.user_id=(select auth.uid()) and p.role='admin'));
grant update(status,admin_note,reviewed_at) on public.ownership_verifications to authenticated;

create or replace function private.cr_refresh_user(p_user uuid)
returns void language plpgsql security definer
set search_path=public,private,pg_temp as $$
declare v_points integer:=0;v_reviews integer:=0;v_verified integer:=0;v_helpful integer:=0;
begin
 if p_user is null then return; end if;
 select coalesce(sum(points),0)::integer into v_points from public.point_events where user_id=p_user;
 select count(*)::integer,count(*) filter(where ownership_status='인증완료')::integer into v_reviews,v_verified from public.reviews where user_id=p_user and status='published';
 select count(*)::integer into v_helpful from public.review_helpful h join public.reviews r on r.id=h.review_id where r.user_id=p_user;
 update public.profiles set points=greatest(v_points,0),level=least(100,greatest(1,1+floor(greatest(v_points,0)/100.0)::integer)),review_count=v_reviews,verified_review_count=v_verified,helpful_received=v_helpful where user_id=p_user;
 insert into public.user_badges(user_id,badge_code)
 select p_user,b.badge_code from public.badges b
 where b.is_active and b.badge_code not in ('longterm_owner','high_mileage')
   and v_points>=b.min_points and v_reviews>=b.min_reviews and v_verified>=b.min_verified_reviews
 on conflict do nothing;
 if exists(select 1 from public.reviews where user_id=p_user and ownership_status='인증완료' and owned_months>=36) then
   insert into public.user_badges(user_id,badge_code) values(p_user,'longterm_owner') on conflict do nothing;
 end if;
 if exists(select 1 from public.reviews where user_id=p_user and ownership_status='인증완료' and mileage_km>=100000) then
   insert into public.user_badges(user_id,badge_code) values(p_user,'high_mileage') on conflict do nothing;
 end if;
end;$$;

create or replace function private.cr_review_reward()
returns trigger language plpgsql security definer
set search_path=public,private,pg_temp as $$
begin
 if tg_op='INSERT' then
   insert into public.point_events(user_id,source_type,source_id,points,reason)
   values(new.user_id,'review',new.id::text,100,'review_created') on conflict do nothing;
 elsif tg_op='UPDATE' and old.ownership_status is distinct from new.ownership_status and new.ownership_status='인증완료' then
   insert into public.point_events(user_id,source_type,source_id,points,reason)
   values(new.user_id,'verification',new.id::text,200,'ownership_verified') on conflict do nothing;
 end if;
 perform private.cr_refresh_user(new.user_id);return new;
end;$$;

create or replace function private.cr_helpful_reward()
returns trigger language plpgsql security definer
set search_path=public,private,pg_temp as $$
declare v_owner uuid;v_count integer;
begin
 select user_id into v_owner from public.reviews where id=coalesce(new.review_id,old.review_id);
 select count(*)::integer into v_count from public.review_helpful where review_id=coalesce(new.review_id,old.review_id);
 update public.reviews set helpful_count=v_count where id=coalesce(new.review_id,old.review_id);
 if tg_op='INSERT' and v_owner is not null then
   insert into public.point_events(user_id,source_type,source_id,points,reason)
   values(v_owner,'helpful',new.review_id::text||':'||new.user_id::text,5,'helpful_received') on conflict do nothing;
 end if;
 perform private.cr_refresh_user(v_owner);return coalesce(new,old);
end;$$;

create or replace function private.cr_sync_verification()
returns trigger language plpgsql security definer
set search_path=public,private,pg_temp as $$
begin
 if old.status is distinct from new.status then
   if new.status='승인' then update public.reviews set ownership_status='인증완료' where id=new.review_id;
   elsif new.status='반려' then update public.reviews set ownership_status='인증반려' where id=new.review_id;
   elsif new.status='대기' then update public.reviews set ownership_status='인증대기' where id=new.review_id;
   end if;
 end if;
 return new;
end;$$;

create or replace function private.cr_new_user_profile()
returns trigger language plpgsql security definer
set search_path=public,private,pg_temp as $$
begin
 insert into public.profiles(user_id,display_name,role)
 values(new.id,coalesce(nullif(split_part(new.email,'@',1),''),'오너'),'user') on conflict(user_id) do nothing;
 return new;
end;$$;

revoke all on function private.cr_refresh_user(uuid) from public,anon,authenticated;
revoke all on function private.cr_review_reward() from public,anon,authenticated;
revoke all on function private.cr_helpful_reward() from public,anon,authenticated;
revoke all on function private.cr_sync_verification() from public,anon,authenticated;
revoke all on function private.cr_new_user_profile() from public,anon,authenticated;

drop trigger if exists cr_review_reward_trigger on public.reviews;
create trigger cr_review_reward_trigger after insert or update of ownership_status on public.reviews for each row execute function private.cr_review_reward();
drop trigger if exists cr_helpful_reward_trigger on public.review_helpful;
create trigger cr_helpful_reward_trigger after insert or delete on public.review_helpful for each row execute function private.cr_helpful_reward();
drop trigger if exists cr_verification_sync_trigger on public.ownership_verifications;
create trigger cr_verification_sync_trigger after update of status on public.ownership_verifications for each row execute function private.cr_sync_verification();
drop trigger if exists cr_auth_user_profile_trigger on auth.users;
create trigger cr_auth_user_profile_trigger after insert on auth.users for each row execute function private.cr_new_user_profile();

-- 회원용 원자적 오너평가 등록/수정 RPC. SECURITY INVOKER + auth.uid() 사용.
create or replace function public.submit_member_owner_review(
 p_generation_id uuid,
 p_ride_comfort int,p_quietness int,p_performance int,p_fuel_efficiency int,p_maintenance_cost int,
 p_reliability int,p_design int,p_convenience int,p_resale_value int,p_repurchase_intent int,
 p_title text,p_body text,p_model_year int default null,p_mileage_km int default null,p_owned_months int default null,
 p_verification_type text default null,p_evidence_url text default null
) returns uuid
language plpgsql security invoker
set search_path=public,pg_temp as $$
declare v_uid uuid:=(select auth.uid());v_review uuid;
begin
 if v_uid is null then raise exception 'authentication required'; end if;
 if char_length(trim(coalesce(p_body,'')))<10 then raise exception 'review body too short'; end if;
 if p_verification_type is not null and p_verification_type not in ('차량등록증','보험','정비내역','기타') then raise exception 'invalid verification type'; end if;

 insert into public.profiles(user_id,display_name,role) values(v_uid,'오너','user') on conflict(user_id) do nothing;

 insert into public.ratings(user_id,generation_id,ride_comfort,quietness,performance,fuel_efficiency,maintenance_cost,reliability,design,convenience,resale_value,repurchase_intent)
 values(v_uid,p_generation_id,p_ride_comfort,p_quietness,p_performance,p_fuel_efficiency,p_maintenance_cost,p_reliability,p_design,p_convenience,p_resale_value,p_repurchase_intent)
 on conflict(user_id,generation_id) do update set
 ride_comfort=excluded.ride_comfort,quietness=excluded.quietness,performance=excluded.performance,fuel_efficiency=excluded.fuel_efficiency,
 maintenance_cost=excluded.maintenance_cost,reliability=excluded.reliability,design=excluded.design,convenience=excluded.convenience,resale_value=excluded.resale_value,
 repurchase_intent=excluded.repurchase_intent,updated_at=now();

 insert into public.reviews(user_id,generation_id,title,body,status,model_year,mileage_km,owned_months,ownership_status)
 values(v_uid,p_generation_id,p_title,p_body,'published',p_model_year,p_mileage_km,p_owned_months,case when p_verification_type is null then '미인증' else '인증대기' end)
 on conflict(user_id,generation_id) do update set
 title=excluded.title,body=excluded.body,model_year=excluded.model_year,mileage_km=excluded.mileage_km,owned_months=excluded.owned_months,
 ownership_status=case when public.reviews.ownership_status='인증완료' then '인증완료' else excluded.ownership_status end,updated_at=now()
 returning id into v_review;

 if p_verification_type is not null then
   insert into public.ownership_verifications(review_id,user_id,verification_type,status,evidence_url)
   values(v_review,v_uid,p_verification_type,'대기',p_evidence_url)
   on conflict(review_id,verification_type) do update set status='대기',evidence_url=excluded.evidence_url,admin_note=null,reviewed_at=null;
 end if;
 return v_review;
end;$$;

revoke all on function public.submit_member_owner_review(uuid,int,int,int,int,int,int,int,int,int,int,text,text,int,int,int,text,text) from public,anon;
grant execute on function public.submit_member_owner_review(uuid,int,int,int,int,int,int,int,int,int,int,text,text,int,int,int,text,text) to authenticated;

-- 기존 데이터 백필
insert into public.point_events(user_id,source_type,source_id,points,reason)
select user_id,'review',id::text,100,'review_created' from public.reviews on conflict do nothing;
insert into public.point_events(user_id,source_type,source_id,points,reason)
select user_id,'verification',id::text,200,'ownership_verified' from public.reviews where ownership_status='인증완료' on conflict do nothing;

do $$ declare u record;begin for u in select user_id from public.profiles loop perform private.cr_refresh_user(u.user_id);end loop;end $$;

commit;
