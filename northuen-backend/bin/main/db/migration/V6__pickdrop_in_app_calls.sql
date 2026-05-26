create table if not exists pickdrop_call_sessions (
    id uuid primary key default gen_random_uuid(),
    order_id uuid not null references pickdrop_orders(id) on delete cascade,
    caller_id uuid not null references users(id) on delete cascade,
    receiver_id uuid not null references users(id) on delete cascade,
    status varchar(20) not null default 'RINGING' check (status in ('RINGING', 'ACTIVE', 'ENDED')),
    ended_at timestamp,
    created_at timestamp not null default now(),
    updated_at timestamp not null default now()
);

create table if not exists pickdrop_call_signals (
    id uuid primary key default gen_random_uuid(),
    call_id uuid not null references pickdrop_call_sessions(id) on delete cascade,
    sender_id uuid not null references users(id) on delete cascade,
    type varchar(30) not null,
    payload text not null,
    created_at timestamp not null default now(),
    updated_at timestamp not null default now()
);

create index if not exists idx_pickdrop_calls_order_status on pickdrop_call_sessions(order_id, status);
create index if not exists idx_pickdrop_calls_caller on pickdrop_call_sessions(caller_id);
create index if not exists idx_pickdrop_calls_receiver on pickdrop_call_sessions(receiver_id);
create index if not exists idx_pickdrop_call_signals_call_time on pickdrop_call_signals(call_id, created_at);

drop trigger if exists pickdrop_call_sessions_updated_at on pickdrop_call_sessions;
create trigger pickdrop_call_sessions_updated_at before update on pickdrop_call_sessions for each row execute function set_updated_at();
drop trigger if exists pickdrop_call_signals_updated_at on pickdrop_call_signals;
create trigger pickdrop_call_signals_updated_at before update on pickdrop_call_signals for each row execute function set_updated_at();
