create table if not exists pickdrop_messages (
    id uuid primary key default gen_random_uuid(),
    order_id uuid not null references pickdrop_orders(id) on delete cascade,
    sender_id uuid not null references users(id) on delete cascade,
    sender_role varchar(20) not null check (sender_role in ('CUSTOMER', 'DRIVER', 'VENDOR', 'ADMIN')),
    body text not null check (length(trim(body)) > 0 and length(body) <= 1000),
    created_at timestamp not null default now(),
    updated_at timestamp not null default now()
);

create index if not exists idx_pickdrop_messages_order_time on pickdrop_messages(order_id, created_at);
create index if not exists idx_pickdrop_messages_sender on pickdrop_messages(sender_id);

drop trigger if exists pickdrop_messages_updated_at on pickdrop_messages;
create trigger pickdrop_messages_updated_at before update on pickdrop_messages for each row execute function set_updated_at();

alter table pickdrop_messages replica identity full;

do $$
begin
    if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
       and not exists (
           select 1
           from pg_publication_tables
           where pubname = 'supabase_realtime'
             and schemaname = 'public'
             and tablename = 'pickdrop_messages'
       ) then
        alter publication supabase_realtime add table pickdrop_messages;
    end if;
end $$;
