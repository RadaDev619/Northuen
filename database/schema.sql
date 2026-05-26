create extension if not exists pgcrypto;

create type user_role as enum ('CUSTOMER', 'DRIVER', 'VENDOR', 'ADMIN');
create type order_type as enum ('FOOD', 'SHOP', 'PARCEL');
create type order_status as enum ('PLACED', 'VENDOR_ACCEPTED', 'VENDOR_REJECTED', 'DRIVER_ASSIGNED', 'ACCEPTED', 'PREPARING', 'READY_FOR_PICKUP', 'PICKED_UP', 'ON_THE_WAY', 'DELIVERED', 'CANCELLED');
create type payment_type as enum ('COD');
create type payment_method as enum ('CASH');
create type payment_status as enum ('PENDING', 'PAID');
create type delivery_status as enum ('PENDING_ASSIGNMENT', 'ASSIGNED', 'ACCEPTED', 'PICKED_UP', 'ON_THE_WAY', 'DELIVERED');
create type settlement_status as enum ('PENDING', 'PAID');
create type pickdrop_status as enum ('PENDING', 'DRIVER_ASSIGNED', 'ACCEPTED', 'ARRIVED_PICKUP', 'PICKED_UP', 'ARRIVED_DROP', 'DELIVERED', 'CANCELLED');

create table users (
    id uuid primary key default gen_random_uuid(),
    full_name varchar(120) not null,
    email varchar(160) not null unique,
    phone varchar(30) not null,
    password_hash varchar(255) not null,
    role varchar(20) not null check (role in ('CUSTOMER', 'DRIVER', 'VENDOR', 'ADMIN')),
    active boolean not null default true,
    created_at timestamp not null default now(),
    updated_at timestamp not null default now()
);

create table vendors (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null unique references users(id) on delete cascade,
    name varchar(160) not null,
    category varchar(30) not null,
    description text not null,
    address text not null,
    latitude numeric(10,7),
    longitude numeric(10,7),
    image_url varchar(255),
    open boolean not null default true,
    created_at timestamp not null default now(),
    updated_at timestamp not null default now()
);

create table products (
    id uuid primary key default gen_random_uuid(),
    vendor_id uuid not null references vendors(id) on delete cascade,
    name varchar(160) not null,
    description text not null,
    price numeric(12,2) not null check (price > 0),
    category varchar(40) not null,
    image_url varchar(255),
    available boolean not null default true,
    created_at timestamp not null default now(),
    updated_at timestamp not null default now()
);

create table carts (
    id uuid primary key default gen_random_uuid(),
    customer_id uuid not null unique references users(id) on delete cascade,
    vendor_id uuid references vendors(id),
    created_at timestamp not null default now(),
    updated_at timestamp not null default now()
);

create table cart_items (
    id uuid primary key default gen_random_uuid(),
    cart_id uuid not null references carts(id) on delete cascade,
    product_id uuid not null references products(id),
    quantity integer not null check (quantity > 0),
    created_at timestamp not null default now(),
    updated_at timestamp not null default now(),
    constraint uk_cart_item_product unique (cart_id, product_id)
);

create table drivers (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null unique references users(id) on delete cascade,
    vehicle_type varchar(60) not null default 'Bike',
    license_number varchar(40),
    is_available boolean not null default false,
    current_latitude numeric(10,7),
    current_longitude numeric(10,7),
    created_at timestamp not null default now(),
    updated_at timestamp not null default now()
);

create table orders (
    id uuid primary key default gen_random_uuid(),
    customer_id uuid not null references users(id),
    vendor_id uuid references vendors(id),
    order_type varchar(20) not null check (order_type in ('FOOD', 'SHOP', 'PARCEL')),
    status varchar(30) not null default 'PLACED' check (status in ('PLACED', 'VENDOR_ACCEPTED', 'VENDOR_REJECTED', 'DRIVER_ASSIGNED', 'ACCEPTED', 'PREPARING', 'READY_FOR_PICKUP', 'PICKED_UP', 'ON_THE_WAY', 'DELIVERED', 'CANCELLED')),
    payment_type varchar(10) not null default 'COD' check (payment_type = 'COD'),
    payment_status varchar(20) not null default 'PENDING' check (payment_status in ('PENDING', 'PAID')),
    subtotal numeric(12,2) not null default 0,
    delivery_fee numeric(12,2) not null default 0,
    total_amount numeric(12,2) not null default 0,
    pickup_address text not null,
    dropoff_address text not null,
    parcel_description text,
    notes text,
    created_at timestamp not null default now(),
    updated_at timestamp not null default now(),
    constraint food_shop_vendor_required check (order_type = 'PARCEL' or vendor_id is not null),
    constraint delivered_requires_paid check (status <> 'DELIVERED' or payment_status = 'PAID')
);

create table order_items (
    id uuid primary key default gen_random_uuid(),
    order_id uuid not null references orders(id) on delete cascade,
    product_id uuid not null references products(id),
    product_name varchar(160) not null,
    unit_price numeric(12,2) not null check (unit_price >= 0),
    quantity integer not null check (quantity > 0),
    line_total numeric(12,2) not null check (line_total >= 0),
    created_at timestamp not null default now(),
    updated_at timestamp not null default now()
);

create table deliveries (
    id uuid primary key default gen_random_uuid(),
    order_id uuid not null unique references orders(id) on delete cascade,
    driver_id uuid references drivers(id),
    status varchar(30) not null default 'PENDING_ASSIGNMENT' check (status in ('PENDING_ASSIGNMENT', 'ASSIGNED', 'ACCEPTED', 'PICKED_UP', 'ON_THE_WAY', 'DELIVERED')),
    picked_up_at timestamp,
    delivered_at timestamp,
    created_at timestamp not null default now(),
    updated_at timestamp not null default now()
);

create table delivery_tracking (
    id uuid primary key default gen_random_uuid(),
    delivery_id uuid not null references deliveries(id) on delete cascade,
    latitude numeric(10,7) not null,
    longitude numeric(10,7) not null,
    created_at timestamp not null default now(),
    updated_at timestamp not null default now()
);

alter table delivery_tracking replica identity full;

create table payments (
    id uuid primary key default gen_random_uuid(),
    order_id uuid not null unique references orders(id) on delete cascade,
    collected_by_driver_id uuid references drivers(id),
    settlement_id uuid,
    method varchar(20) not null default 'CASH' check (method = 'CASH'),
    status varchar(20) not null default 'PENDING' check (status in ('PENDING', 'PAID')),
    amount numeric(12,2) not null check (amount >= 0),
    collected_at timestamp,
    created_at timestamp not null default now(),
    updated_at timestamp not null default now()
);

create table driver_cash_settlements (
    id uuid primary key default gen_random_uuid(),
    driver_id uuid not null references drivers(id),
    payment_id uuid not null unique references payments(id),
    amount numeric(12,2) not null check (amount >= 0),
    status varchar(20) not null default 'PENDING' check (status in ('PENDING', 'PAID')),
    settled_at timestamp,
    notes text,
    created_at timestamp not null default now(),
    updated_at timestamp not null default now()
);

alter table payments
    add constraint fk_payments_settlement foreign key (settlement_id) references driver_cash_settlements(id);

create table reviews (
    id uuid primary key default gen_random_uuid(),
    order_id uuid not null references orders(id) on delete cascade,
    customer_id uuid not null references users(id),
    vendor_id uuid references vendors(id),
    driver_id uuid references drivers(id),
    vendor_rating integer check (vendor_rating between 1 and 5),
    driver_rating integer check (driver_rating between 1 and 5),
    comment text,
    created_at timestamp not null default now(),
    updated_at timestamp not null default now()
);

create table notifications (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references users(id) on delete cascade,
    title varchar(140) not null,
    message text not null,
    read boolean not null default false,
    created_at timestamp not null default now(),
    updated_at timestamp not null default now()
);

create table pickdrop_orders (
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

create table driver_live_locations (
    driver_id uuid not null references drivers(id) on delete cascade,
    order_id uuid not null references pickdrop_orders(id) on delete cascade,
    lat numeric(10,7) not null,
    lng numeric(10,7) not null,
    heading numeric(6,2),
    speed numeric(6,2),
    updated_at timestamp not null default now(),
    primary key (driver_id, order_id)
);

create table pickdrop_messages (
    id uuid primary key default gen_random_uuid(),
    order_id uuid not null references pickdrop_orders(id) on delete cascade,
    sender_id uuid not null references users(id) on delete cascade,
    sender_role varchar(20) not null check (sender_role in ('CUSTOMER', 'DRIVER', 'VENDOR', 'ADMIN')),
    body text not null check (length(trim(body)) > 0 and length(body) <= 1000),
    created_at timestamp not null default now(),
    updated_at timestamp not null default now()
);

create index idx_users_email on users(email);
create index idx_users_role on users(role);
create index idx_vendors_category on vendors(category);
create index idx_products_vendor on products(vendor_id);
create index idx_carts_customer on carts(customer_id);
create index idx_cart_items_cart on cart_items(cart_id);
create index idx_orders_customer on orders(customer_id);
create index idx_orders_vendor on orders(vendor_id);
create index idx_orders_status on orders(status);
create index idx_deliveries_driver on deliveries(driver_id);
create index idx_tracking_delivery_time on delivery_tracking(delivery_id, created_at desc);
create index idx_payments_status on payments(status);
create index idx_settlements_driver on driver_cash_settlements(driver_id);
create index idx_settlements_status on driver_cash_settlements(status);
create index idx_reviews_order on reviews(order_id);
create index idx_pickdrop_customer on pickdrop_orders(customer_id);
create index idx_pickdrop_driver on pickdrop_orders(driver_id);
create index idx_pickdrop_status on pickdrop_orders(status);
create index idx_pickdrop_created on pickdrop_orders(created_at);
create index idx_driver_live_order on driver_live_locations(order_id);
create index idx_driver_live_updated on driver_live_locations(updated_at);
create index idx_pickdrop_messages_order_time on pickdrop_messages(order_id, created_at);
create index idx_pickdrop_messages_sender on pickdrop_messages(sender_id);

create or replace function set_updated_at()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

create trigger users_updated_at before update on users for each row execute function set_updated_at();
create trigger vendors_updated_at before update on vendors for each row execute function set_updated_at();
create trigger products_updated_at before update on products for each row execute function set_updated_at();
create trigger carts_updated_at before update on carts for each row execute function set_updated_at();
create trigger cart_items_updated_at before update on cart_items for each row execute function set_updated_at();
create trigger drivers_updated_at before update on drivers for each row execute function set_updated_at();
create trigger orders_updated_at before update on orders for each row execute function set_updated_at();
create trigger order_items_updated_at before update on order_items for each row execute function set_updated_at();
create trigger deliveries_updated_at before update on deliveries for each row execute function set_updated_at();
create trigger delivery_tracking_updated_at before update on delivery_tracking for each row execute function set_updated_at();
create trigger payments_updated_at before update on payments for each row execute function set_updated_at();
create trigger driver_cash_settlements_updated_at before update on driver_cash_settlements for each row execute function set_updated_at();
create trigger reviews_updated_at before update on reviews for each row execute function set_updated_at();
create trigger notifications_updated_at before update on notifications for each row execute function set_updated_at();
create trigger pickdrop_orders_updated_at before update on pickdrop_orders for each row execute function set_updated_at();
create trigger pickdrop_messages_updated_at before update on pickdrop_messages for each row execute function set_updated_at();

alter table delivery_tracking replica identity full;
alter table driver_live_locations replica identity full;
alter table pickdrop_messages replica identity full;
