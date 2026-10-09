-- Bridge to China — Volunteer Accounts Schema
-- Run this once in your Supabase project: Dashboard → SQL Editor → New Query → paste → Run

-- One row per volunteer, linked to Supabase's built-in auth.users table.
create table if not exists profiles (
  id uuid references auth.users on delete cascade primary key,
  full_name text not null,
  role text not null default 'volunteer' check (role in ('volunteer')),
  country text,
  languages text,
  bio text,
  created_at timestamp with time zone default now()
);

-- Row Level Security: a volunteer can only ever see/edit their OWN row.
alter table profiles enable row level security;

create policy "Volunteers can view their own profile"
  on profiles for select
  using (auth.uid() = id);

create policy "Volunteers can insert their own profile"
  on profiles for insert
  with check (auth.uid() = id);

create policy "Volunteers can update their own profile"
  on profiles for update
  using (auth.uid() = id);

-- ----------------------------------------------------------------------
-- PHASE 1 ADDITION: the volunteer application & screening pipeline
-- ----------------------------------------------------------------------
-- Run this part too (same SQL Editor, can go right after the above).
-- This is what makes "creating an account" different from "being an
-- approved volunteer" — exactly what the spec calls for.

-- Marks a profile as an admin so they can review applications.
-- There is NO self-serve way to become an admin — you set this manually:
--   update profiles set is_admin = true where id = 'the-persons-uuid';
alter table profiles add column if not exists is_admin boolean not null default false;

create table if not exists applications (
  id uuid references auth.users on delete cascade primary key,

  status text not null default 'account_created' check (status in (
    'account_created',
    'email_verified',
    'profile_complete',
    'background_complete',
    'scenarios_complete',
    'assessment_english_complete',
    'assessment_chinese_complete',
    'orientation_complete',
    'submitted',
    'under_review',
    'approved',
    'needs_additional_training',
    'not_approved',
    'suspended'
  )),

  -- Section 3: personal information
  first_name text,
  last_name text,
  preferred_name text,
  country text,
  city_region text,
  timezone text,
  date_of_birth date,
  profile_picture_url text,
  native_language text,
  other_languages text,
  school_work_status text,
  bio text,

  -- Section 4: language background (self-reported — compared against
  -- assessment scores later, per the spec's instruction not to trust these alone)
  english_is_native boolean,
  english_years text,
  english_formal_study boolean,
  english_taught_before boolean,
  english_lived_abroad boolean,
  english_speaking_comfort int check (english_speaking_comfort between 1 and 5),
  english_understanding_comfort int check (english_understanding_comfort between 1 and 5),

  chinese_languages text,          -- e.g. "Mandarin, Cantonese"
  chinese_years text,
  chinese_learned_where text,
  chinese_lived_immersion boolean,
  chinese_speaking_comfort int check (chinese_speaking_comfort between 1 and 5),
  chinese_understanding_comfort int check (chinese_understanding_comfort between 1 and 5),
  chinese_can_read boolean,
  chinese_can_write boolean,

  -- Section 5: teaching experience
  taught_before boolean,
  teaching_subjects text,
  taught_english_before boolean,
  student_count_taught text,
  age_groups_taught text,
  taught_online_before boolean,
  taught_other_language_students boolean,
  teaching_experience_text text,

  -- Section 6: scenario / judgment questions
  scenario_1 text,
  scenario_2 text,
  scenario_3 text,
  scenario_4 text,

  -- Section 19: availability
  avail_days text,
  avail_start_time text,
  avail_end_time text,
  preferred_lesson_length text,
  max_students int,
  max_weekly_hours int,
  preferred_age_groups text,
  preferred_student_levels text,

  -- Admin-only notes (never shown to the volunteer or students)
  reviewer_notes text,

  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

alter table applications enable row level security;

-- A volunteer can see and edit only their own application...
create policy "Volunteers manage their own application"
  on applications for all
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- ...but an admin can see every application, to actually review them.
create policy "Admins can view all applications"
  on applications for select
  using (exists (select 1 from profiles where id = auth.uid() and is_admin = true));

create policy "Admins can update any application"
  on applications for update
  using (exists (select 1 from profiles where id = auth.uid() and is_admin = true));

-- Keeps updated_at current automatically.
create or replace function set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists applications_updated_at on applications;
create trigger applications_updated_at
  before update on applications
  for each row execute function set_updated_at();

-- ----------------------------------------------------------------------
-- PHASE 2 ADDITION: assessments (written, listening, speaking) + orientation
-- ----------------------------------------------------------------------
-- Run this after Phase 1 above.

alter table applications add column if not exists english_mc_score int;        -- grammar/vocab/reading, auto-graded /100
alter table applications add column if not exists english_listening_score int; -- auto-graded /100
alter table applications add column if not exists english_essay_text text;     -- NOT auto-graded — for reviewer
alter table applications add column if not exists english_speaking_notes text; -- reviewer's notes after listening to recordings

alter table applications add column if not exists chinese_mc_score int;
alter table applications add column if not exists chinese_listening_score int;
alter table applications add column if not exists chinese_essay_text text;
alter table applications add column if not exists chinese_speaking_notes text;

alter table applications add column if not exists orientation_quiz_score int;

-- One row per recorded speaking-prompt answer, so a reviewer can play each one back.
create table if not exists speaking_recordings (
  id uuid default gen_random_uuid() primary key,
  application_id uuid references applications(id) on delete cascade not null,
  language text not null check (language in ('english','chinese')),
  prompt_index int not null,
  storage_path text not null,
  created_at timestamp with time zone default now()
);

alter table speaking_recordings enable row level security;

create policy "Volunteers manage their own recordings"
  on speaking_recordings for all
  using (auth.uid() = application_id)
  with check (auth.uid() = application_id);

create policy "Admins can view all recordings"
  on speaking_recordings for select
  using (exists (select 1 from profiles where id = auth.uid() and is_admin = true));

-- Per-section score breakdowns + the raw answers (so an admin can re-check).
alter table applications add column if not exists english_breakdown jsonb;   -- {grammar, vocabulary, reading, listening} each /100
alter table applications add column if not exists chinese_breakdown jsonb;
alter table applications add column if not exists english_answers jsonb;
alter table applications add column if not exists chinese_answers jsonb;

-- ----------------------------------------------------------------------
-- STORAGE: private bucket for speaking recordings, done in SQL
-- ----------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('recordings', 'recordings', false)
on conflict (id) do nothing;

create policy "Volunteers upload own recordings" on storage.objects for insert to authenticated
  with check (bucket_id = 'recordings' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "Volunteers read own recordings" on storage.objects for select to authenticated
  using (bucket_id = 'recordings' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "Volunteers delete own recordings" on storage.objects for delete to authenticated
  using (bucket_id = 'recordings' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "Admins read all recordings" on storage.objects for select to authenticated
  using (bucket_id = 'recordings' and exists (select 1 from profiles where id = auth.uid() and is_admin = true));

-- ----------------------------------------------------------------------
-- SECURITY GUARDS — IMPORTANT, run these.
-- Without them, row-level security alone would let a volunteer call the API
-- directly and set their own status to 'approved' or make themselves an
-- admin. These triggers block that. (When YOU run SQL in the Supabase
-- dashboard, auth.uid() is null, so your manual admin changes still work.)
-- ----------------------------------------------------------------------
create or replace function guard_profile_changes() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then return new; end if;
  if tg_op = 'INSERT' then
    new.is_admin := false;
    return new;
  end if;
  if new.is_admin is distinct from old.is_admin then
    raise exception 'is_admin can only be changed by the site owner';
  end if;
  return new;
end $$;

drop trigger if exists profiles_guard on profiles;
create trigger profiles_guard before insert or update on profiles
  for each row execute function guard_profile_changes();

create or replace function guard_application_changes() returns trigger
language plpgsql security definer set search_path = public as $$
declare caller_is_admin boolean;
begin
  if auth.uid() is null then return new; end if;
  select coalesce((select is_admin from profiles where id = auth.uid()), false) into caller_is_admin;
  if caller_is_admin then return new; end if;

  if tg_op = 'INSERT' then
    new.status := 'account_created';
    new.reviewer_notes := null;
    return new;
  end if;

  if new.reviewer_notes is distinct from old.reviewer_notes then
    raise exception 'reviewer notes are admin-only';
  end if;
  if new.status is distinct from old.status then
    if new.status in ('under_review','approved','needs_additional_training','not_approved','suspended') then
      raise exception 'only an administrator can set that status';
    end if;
    if old.status in ('under_review','approved','needs_additional_training','not_approved','suspended') then
      raise exception 'status was set by an administrator and cannot be changed by the volunteer';
    end if;
  end if;
  return new;
end $$;

drop trigger if exists applications_guard on applications;
create trigger applications_guard before insert or update on applications
  for each row execute function guard_application_changes();

-- KNOWN LIMITATION (be aware): multiple-choice and listening scores are
-- calculated in the volunteer's browser, so a technically skilled person
-- could submit a forged score. That's why approval is always a human
-- decision, and why the raw answers, essay, and voice recordings (which
-- can't be faked the same way) are what an admin actually reads. The proper
-- long-term fix is grading on the server (a Supabase Edge Function).
