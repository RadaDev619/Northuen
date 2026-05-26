alter table delivery_tracking replica identity full;

do $$
begin
    if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
        if not exists (
            select 1
            from pg_publication_tables
            where pubname = 'supabase_realtime'
              and schemaname = 'public'
              and tablename = 'delivery_tracking'
        ) then
            alter publication supabase_realtime add table delivery_tracking;
        end if;
    end if;
end $$;
