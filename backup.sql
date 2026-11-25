-- Αντίγραφα ασφαλείας: τρέξε το ολόκληρο μία φορά στο SQL Editor

-- 1) Ιστορικό εκδόσεων: κάθε αποθήκευση κρατά την προηγούμενη μορφή (τελευταίες 200)
create table if not exists public.app_state_history (
  hid bigserial primary key, saved_at timestamptz default now(), data jsonb
);
alter table public.app_state_history enable row level security;
revoke all on public.app_state_history from anon;
grant select, delete on public.app_state_history to authenticated;
grant usage, select on sequence public.app_state_history_hid_seq to authenticated;

create or replace function public.keep_state_history() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'UPDATE' and old.data is distinct from new.data then
    -- το πολύ μία έκδοση ανά 10 λεπτά, για να μη γεμίζει από μικροαλλαγές
    if not exists (select 1 from app_state_history where saved_at > now() - interval '10 minutes') then
      insert into app_state_history(data) values (old.data);
      delete from app_state_history where hid not in (select hid from app_state_history order by hid desc limit 200);
    end if;
  end if;
  return new;
end $$;
drop trigger if exists trg_keep_state_history on public.app_state;
create trigger trg_keep_state_history before update on public.app_state
  for each row execute function public.keep_state_history();

drop policy if exists h_adm on public.app_state_history;
create policy h_adm on public.app_state_history for select using (is_admin());
drop policy if exists h_del on public.app_state_history;
create policy h_del on public.app_state_history for delete using (is_admin());

-- 2) Χρήστης «backup» μόνο για ανάγνωση (για το αυτόματο αντίγραφο στο Google Drive)
alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles add constraint profiles_role_check check (role in ('admin','unit','backup'));
create or replace function public.is_backup() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from profiles where user_id = auth.uid() and role = 'backup')
$$;
grant execute on function public.is_backup() to authenticated;
drop policy if exists s_bak on public.app_state;
create policy s_bak on public.app_state for select using (is_backup());

-- ΜΕΤΑ: Authentication → Users → Add user: backup@polykatoikia.app, κωδικός, Auto Confirm User
-- και τρέξε:
-- insert into public.profiles (user_id, username, role)
--   select id, 'backup', 'backup' from auth.users where email = 'backup@polykatoikia.app';
