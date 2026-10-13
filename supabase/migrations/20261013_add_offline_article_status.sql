alter table public.articles drop constraint if exists articles_status_check;

alter table public.articles
  add constraint articles_status_check
  check (status in ('draft', 'published', 'offline', 'rejected'));
