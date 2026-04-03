-- Cal A2 groundwork (Sprint 3)
-- Supabase schema for calendar connections + synced event cache with user-scoped RLS.

create table if not exists public.user_calendar_connections (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    provider text not null,
    access_token text,
    refresh_token text,
    token_expires_at timestamptz,
    selected_calendar_ids text[],
    sync_preferences jsonb default '{}'::jsonb,
    last_synced_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create unique index if not exists user_calendar_connections_user_provider_idx
    on public.user_calendar_connections (user_id, provider);

create table if not exists public.synced_calendar_events (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    provider text not null,
    provider_event_id text not null,
    title text not null,
    start_at timestamptz,
    all_day boolean not null default false,
    synced_at timestamptz not null default now(),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create unique index if not exists synced_calendar_events_provider_unique_idx
    on public.synced_calendar_events (user_id, provider, provider_event_id);

alter table public.user_calendar_connections enable row level security;
alter table public.synced_calendar_events enable row level security;

create policy if not exists user_calendar_connections_self
    on public.user_calendar_connections
    for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create policy if not exists synced_calendar_events_self
    on public.synced_calendar_events
    for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create or replace function public.set_updated_at_timestamp()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists set_user_calendar_connections_updated_at on public.user_calendar_connections;
create trigger set_user_calendar_connections_updated_at
before update on public.user_calendar_connections
for each row execute function public.set_updated_at_timestamp();

drop trigger if exists set_synced_calendar_events_updated_at on public.synced_calendar_events;
create trigger set_synced_calendar_events_updated_at
before update on public.synced_calendar_events
for each row execute function public.set_updated_at_timestamp();
