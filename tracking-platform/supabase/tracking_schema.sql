create extension if not exists pgcrypto;

create table if not exists runner_locations_latest (
    order_id uuid primary key,
    runner_id uuid not null,
    status varchar(40) not null,
    lat numeric(10,7) not null,
    lng numeric(10,7) not null,
    snapped_lat numeric(10,7),
    snapped_lng numeric(10,7),
    heading numeric(6,2),
    speed numeric(8,2),
    accuracy numeric(8,2),
    recorded_at timestamptz not null,
    updated_at timestamptz not null default now()
);

create table if not exists runner_location_history (
    id uuid primary key default gen_random_uuid(),
    order_id uuid not null,
    runner_id uuid not null,
    status varchar(40) not null,
    lat numeric(10,7) not null,
    lng numeric(10,7) not null,
    heading numeric(6,2),
    speed numeric(8,2),
    accuracy numeric(8,2),
    source varchar(20) not null default 'raw' check (source in ('raw', 'snapped')),
    recorded_at timestamptz not null,
    created_at timestamptz not null default now()
);

create table if not exists delivery_routes (
    order_id uuid primary key,
    encoded_polyline text not null,
    distance_meters integer not null default 0,
    duration_seconds integer not null default 0,
    eta timestamptz not null,
    calculated_at timestamptz not null default now()
);

create index if not exists idx_runner_history_order_time
    on runner_location_history(order_id, recorded_at desc);

create index if not exists idx_runner_history_runner_time
    on runner_location_history(runner_id, recorded_at desc);

alter table runner_locations_latest replica identity full;
alter table delivery_routes replica identity full;

do $$
begin
    if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
       and not exists (
           select 1
           from pg_publication_tables
           where pubname = 'supabase_realtime'
             and schemaname = 'public'
             and tablename = 'runner_locations_latest'
       ) then
        alter publication supabase_realtime add table runner_locations_latest;
    end if;

    if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
       and not exists (
           select 1
           from pg_publication_tables
           where pubname = 'supabase_realtime'
             and schemaname = 'public'
             and tablename = 'delivery_routes'
       ) then
        alter publication supabase_realtime add table delivery_routes;
    end if;
end $$;

alter table runner_locations_latest enable row level security;
alter table runner_location_history enable row level security;
alter table delivery_routes enable row level security;

-- Replace these broad read policies with order membership checks once auth
-- claims and order membership tables are connected to this module.
drop policy if exists "tracking latest read" on runner_locations_latest;
create policy "tracking latest read"
    on runner_locations_latest for select
    using (true);

drop policy if exists "delivery routes read" on delivery_routes;
create policy "delivery routes read"
    on delivery_routes for select
    using (true);
