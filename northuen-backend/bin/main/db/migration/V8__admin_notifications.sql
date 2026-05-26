alter table notifications
    add column if not exists type varchar(40) not null default 'SYSTEM',
    add column if not exists target_role varchar(20),
    add column if not exists sent_by_admin_id uuid references users(id),
    add column if not exists priority integer not null default 0,
    add column if not exists read_at timestamp;

create index if not exists idx_notifications_user_read on notifications(user_id, read, created_at desc);
create index if not exists idx_notifications_target_role on notifications(target_role);
create index if not exists idx_notifications_type on notifications(type);
