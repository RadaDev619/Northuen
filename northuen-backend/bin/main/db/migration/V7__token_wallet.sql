create table if not exists wallet_accounts (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null unique references users(id) on delete cascade,
    token_balance numeric(12,2) not null default 0 check (token_balance >= 0),
    active boolean not null default true,
    created_at timestamp not null default now(),
    updated_at timestamp not null default now()
);

create table if not exists wallet_transactions (
    id uuid primary key default gen_random_uuid(),
    wallet_id uuid not null references wallet_accounts(id) on delete cascade,
    type varchar(30) not null check (type in ('MANUAL_RECHARGE', 'ADJUSTMENT')),
    amount numeric(12,2) not null,
    balance_after numeric(12,2) not null check (balance_after >= 0),
    reference varchar(80) not null unique,
    note varchar(255) not null,
    created_at timestamp not null default now(),
    updated_at timestamp not null default now()
);

create index if not exists idx_wallet_accounts_user on wallet_accounts(user_id);
create index if not exists idx_wallet_transactions_wallet_time on wallet_transactions(wallet_id, created_at desc);
