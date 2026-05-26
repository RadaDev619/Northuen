do $$ begin create type pickdrop_status as enum ('PENDING', 'DRIVER_ASSIGNED', 'ACCEPTED', 'ARRIVED_PICKUP', 'PICKED_UP', 'ARRIVED_DROP', 'DELIVERED', 'CANCELLED'); exception when duplicate_object then null; end $$;

create table if not exists pickdrop_orders (
    id uuid primary key default gen_random_uuid(),
    customer_id uuid not null references users(id) on delete cascade,
    driver_id uuid references drivers(id),
    pickup_address text not null,
    pickup_lat numeric(10,7) not null,
    pickup_lng numeric(10,7) not null,
    drop_address text not null,
    drop_lat numeric(10,7) not null,
    drop_lng numeric(10,7) not null,
    item_type varchar(80) not null,
    item_description text not null,
    estimated_distance_km numeric(8,2) not null check (estimated_distance_km >= 0),
    estimated_price numeric(12,2) not null check (estimated_price >= 0),
    status varchar(30) not null default 'PENDING' check (status in ('PENDING', 'DRIVER_ASSIGNED', 'ACCEPTED', 'ARRIVED_PICKUP', 'PICKED_UP', 'ARRIVED_DROP', 'DELIVERED', 'CANCELLED')),
    payment_status varchar(20) not null default 'PENDING' check (payment_status in ('PENDING', 'PAID')),
    created_at timestamp not null default now(),
    updated_at timestamp not null default now()
);

create table if not exists driver_live_locations (
    driver_id uuid not null references drivers(id) on delete cascade,
    order_id uuid not null references pickdrop_orders(id) on delete cascade,
    lat numeric(10,7) not null,
    lng numeric(10,7) not null,
    heading numeric(6,2),
    speed numeric(6,2),
    updated_at timestamp not null default now(),
    primary key (driver_id, order_id)
);

create index if not exists idx_pickdrop_customer on pickdrop_orders(customer_id);
create index if not exists idx_pickdrop_driver on pickdrop_orders(driver_id);
create index if not exists idx_pickdrop_status on pickdrop_orders(status);
create index if not exists idx_pickdrop_created on pickdrop_orders(created_at);
create index if not exists idx_driver_live_order on driver_live_locations(order_id);
create index if not exists idx_driver_live_updated on driver_live_locations(updated_at);

alter table driver_live_locations replica identity full;

do $$
begin
    if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
       and not exists (
           select 1
           from pg_publication_tables
           where pubname = 'supabase_realtime'
             and schemaname = 'public'
             and tablename = 'driver_live_locations'
       ) then
        alter publication supabase_realtime add table driver_live_locations;
    end if;
end $$;
