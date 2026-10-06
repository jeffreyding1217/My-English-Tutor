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

-- That's it for now. This gives you real signup/login/logout and a profiles
-- table to show the volunteer's name on their dashboard. Lesson scheduling,
-- hours tracking, and certificates are NOT in this schema yet — the
-- dashboard still shows sample data for those until that's built next.
