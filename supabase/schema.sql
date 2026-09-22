create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.sources (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  platform text not null,
  source_url text,
  feed_url text,
  language text not null default 'zh-CN',
  focus text[] not null default '{}',
  priority text not null default 'B' check (priority in ('A', 'B', 'C')),
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.source_items (
  id uuid primary key default gen_random_uuid(),
  source_id uuid not null references public.sources(id) on delete cascade,
  external_id text not null,
  title text not null,
  description text,
  source_url text not null,
  episode_url text,
  play_url text,
  published_at timestamptz,
  raw_payload jsonb not null default '{}'::jsonb,
  fetched_at timestamptz not null default now(),
  unique (source_id, external_id)
);

create table if not exists public.articles (
  id uuid primary key default gen_random_uuid(),
  source_item_id uuid unique references public.source_items(id) on delete set null,
  status text not null default 'draft' check (status in ('draft', 'published', 'rejected')),
  title text not null,
  summary text not null default '',
  guest_name text not null default '',
  guest_intro text not null default '',
  key_points jsonb not null default '[]'::jsonb,
  insights jsonb not null default '[]'::jsonb,
  editorial_analysis text not null default '',
  content text not null default '',
  category text not null default '模型与产品',
  tags text[] not null default '{}',
  source_name text not null default '',
  source_url text not null,
  episode_url text,
  play_url text,
  source_published_at timestamptz,
  model_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  published_at timestamptz
);

create table if not exists public.subscribers (
  id uuid primary key default gen_random_uuid(),
  email text not null unique,
  status text not null default 'active' check (status in ('active', 'unsubscribed')),
  created_at timestamptz not null default now()
);

create table if not exists public.review_actions (
  id uuid primary key default gen_random_uuid(),
  article_id uuid not null references public.articles(id) on delete cascade,
  action text not null check (action in ('edit', 'publish', 'reject', 'unpublish', 'regenerate')),
  note text,
  actor_email text not null default '',
  created_at timestamptz not null default now()
);

alter table public.source_items add column if not exists episode_url text;
alter table public.source_items add column if not exists play_url text;
alter table public.articles add column if not exists content text not null default '';
alter table public.articles add column if not exists guest_name text not null default '';
alter table public.articles add column if not exists insights jsonb not null default '[]'::jsonb;
alter table public.articles add column if not exists episode_url text;
alter table public.articles add column if not exists play_url text;

create index if not exists source_items_published_at_idx on public.source_items (published_at desc);
create index if not exists articles_status_published_at_idx on public.articles (status, published_at desc);
create index if not exists articles_category_idx on public.articles (category);
create index if not exists articles_tags_idx on public.articles using gin (tags);

drop trigger if exists sources_set_updated_at on public.sources;
create trigger sources_set_updated_at
  before update on public.sources
  for each row execute function public.set_updated_at();

drop trigger if exists articles_set_updated_at on public.articles;
create trigger articles_set_updated_at
  before update on public.articles
  for each row execute function public.set_updated_at();

create or replace function public.is_admin()
returns boolean
language sql
stable
as $$
  select coalesce((auth.jwt() ->> 'email') = 'maojingling25@gmail.com', false);
$$;

alter table public.sources enable row level security;
alter table public.source_items enable row level security;
alter table public.articles enable row level security;
alter table public.review_actions enable row level security;
alter table public.subscribers enable row level security;

drop policy if exists "public can read enabled sources" on public.sources;
create policy "public can read enabled sources"
  on public.sources for select
  using (enabled = true or public.is_admin());

drop policy if exists "admin manages sources" on public.sources;
create policy "admin manages sources"
  on public.sources for all
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "admin reads source items" on public.source_items;
create policy "admin reads source items"
  on public.source_items for select
  using (public.is_admin());

drop policy if exists "public reads published articles" on public.articles;
create policy "public reads published articles"
  on public.articles for select
  using (status = 'published' or public.is_admin());

drop policy if exists "admin manages articles" on public.articles;
create policy "admin manages articles"
  on public.articles for all
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "admin reads review actions" on public.review_actions;
create policy "admin reads review actions"
  on public.review_actions for select
  using (public.is_admin());

drop policy if exists "admin creates review actions" on public.review_actions;
create policy "admin creates review actions"
  on public.review_actions for insert
  with check (public.is_admin());

drop policy if exists "public can subscribe" on public.subscribers;
create policy "public can subscribe"
  on public.subscribers for insert
  with check (status = 'active');

drop policy if exists "admin reads subscribers" on public.subscribers;
create policy "admin reads subscribers"
  on public.subscribers for select
  using (public.is_admin());
