-- ============================================================
--  INTERVENE — Supabase schema
--  Mental Wellbeing • Anti-Bullying • Awareness, Empathy & Action
--  Run in Supabase SQL editor (or `supabase db push`).
-- ============================================================

-- ---------- ENUMS ----------
create type user_role     as enum ('student','therapist','admin');
create type report_status as enum ('submitted','under_review','action_taken','resolved','dismissed');
create type report_category as enum ('bullying','harassment','cyberbullying','discrimination');

-- ---------- PROFILES (1:1 with auth.users) ----------
create table public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  name        text,
  email       text,
  role        user_role not null default 'student',
  avatar_url  text,
  school      text,
  created_at  timestamptz not null default now()
);

-- ---------- MOODS ----------
create table public.moods (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  mood       smallint not null check (mood between 1 and 5),
  note       text,
  created_at timestamptz not null default now()
);
create index moods_user_idx on public.moods(user_id, created_at desc);

-- ---------- REPORTS (anti-bullying) ----------
create table public.reports (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid references public.profiles(id) on delete set null, -- null = anonymous
  is_anonymous  boolean not null default true,
  category      report_category not null,
  description   text not null,
  evidence_url  text,
  status        report_status not null default 'submitted',
  tracking_code text unique default ('IV-' || lpad((floor(random()*9999))::text, 4, '0')),
  created_at    timestamptz not null default now()
);

-- ---------- RESOURCES (hub) ----------
create table public.resources (
  id         uuid primary key default gen_random_uuid(),
  title      text not null,
  content    text,
  category   text,
  type       text default 'article',     -- article | video | guide
  image_url  text,
  created_at timestamptz not null default now()
);

-- ---------- EVENTS & CAMPAIGNS ----------
create table public.events (
  id          uuid primary key default gen_random_uuid(),
  title       text not null,
  description text,
  type        text,                       -- workshop | webinar | campaign | school event
  date        timestamptz not null,
  created_at  timestamptz not null default now()
);

-- ---------- THERAPIST PROFILES ----------
create table public.therapist_profiles (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid references public.profiles(id) on delete cascade,
  name           text not null,
  specialization text,
  qualifications text,
  bio            text,
  image_url      text,
  verified       boolean not null default false,
  created_at     timestamptz not null default now()
);

-- ---------- COMMUNITY POSTS (safe space) ----------
create table public.community_posts (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid references public.profiles(id) on delete set null,
  is_anonymous boolean not null default true,
  content      text not null,
  flagged      boolean not null default false,
  created_at   timestamptz not null default now()
);

-- ---------- VOLUNTEERS ----------
create table public.volunteers (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  email      text not null,
  grade      text,
  role       text,                        -- ambassador | peer supporter | campaign
  reason     text,
  created_at timestamptz not null default now()
);

-- ---------- NEWSLETTER ----------
create table public.subscribers (
  id           uuid primary key default gen_random_uuid(),
  name         text,
  email        text not null unique,
  organization text,
  created_at   timestamptz not null default now()
);

-- ---------- SOCIAL LINKS (admin-managed) ----------
create table public.social_links (
  id        uuid primary key default gen_random_uuid(),
  platform  text not null,
  handle    text,
  url       text,
  followers text,
  sort      int default 0
);

-- ============================================================
--  ROW LEVEL SECURITY
-- ============================================================
alter table public.profiles          enable row level security;
alter table public.moods             enable row level security;
alter table public.reports           enable row level security;
alter table public.resources         enable row level security;
alter table public.events            enable row level security;
alter table public.therapist_profiles enable row level security;
alter table public.community_posts   enable row level security;
alter table public.volunteers        enable row level security;
alter table public.subscribers       enable row level security;
alter table public.social_links      enable row level security;

-- helper: is current user an admin?
create or replace function public.is_admin() returns boolean
language sql security definer stable as $$
  select exists(select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;

-- profiles: a user sees/edits their own; admins see all
create policy "own profile read"   on public.profiles for select using (auth.uid() = id or public.is_admin());
create policy "own profile write"  on public.profiles for update using (auth.uid() = id);
create policy "insert own profile"  on public.profiles for insert with check (auth.uid() = id);

-- moods: strictly private to the owner
create policy "own moods"          on public.moods for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- reports: insert by anyone (incl. anonymous), read by owner or admin, update by admin
create policy "create report"      on public.reports for insert with check (true);
create policy "read own/admin"     on public.reports for select using (auth.uid() = user_id or public.is_admin());
create policy "admin update report" on public.reports for update using (public.is_admin());

-- resources & events: public read, admin write
create policy "public read res"    on public.resources for select using (true);
create policy "admin write res"    on public.resources for all using (public.is_admin()) with check (public.is_admin());
create policy "public read ev"     on public.events for select using (true);
create policy "admin write ev"     on public.events for all using (public.is_admin()) with check (public.is_admin());

-- therapist profiles: public read; therapist edits own; admin verifies
create policy "public read ther"   on public.therapist_profiles for select using (true);
create policy "ther write own"     on public.therapist_profiles for all using (auth.uid() = user_id or public.is_admin()) with check (auth.uid() = user_id or public.is_admin());

-- community: read for authenticated, insert own, admin moderates
create policy "read posts"         on public.community_posts for select using (auth.role() = 'authenticated');
create policy "insert post"        on public.community_posts for insert with check (auth.uid() = user_id or user_id is null);
create policy "admin moderate"     on public.community_posts for update using (public.is_admin());

-- volunteers / subscribers: anyone can insert, admins read
create policy "apply volunteer"    on public.volunteers for insert with check (true);
create policy "admin read vol"     on public.volunteers for select using (public.is_admin());
create policy "subscribe"          on public.subscribers for insert with check (true);
create policy "admin read subs"    on public.subscribers for select using (public.is_admin());

-- social links: public read, admin write
create policy "public read social" on public.social_links for select using (true);
create policy "admin write social" on public.social_links for all using (public.is_admin()) with check (public.is_admin());

-- ============================================================
--  AUTO-CREATE PROFILE ON SIGNUP
-- ============================================================
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer as $$
begin
  insert into public.profiles (id, name, email, role)
  values (new.id, new.raw_user_meta_data->>'name', new.email,
          coalesce((new.raw_user_meta_data->>'role')::user_role, 'student'));
  return new;
end; $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
