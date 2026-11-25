-- Βλάβες/αιτήματα και ψηφοφορίες: τρέξε το ολόκληρο μία φορά στο SQL Editor
create table if not exists public.requests (
  id bigserial primary key, unit_id text not null, title text not null, text text,
  status text not null default 'open', reply text default '', created_at timestamptz default now()
);
create table if not exists public.votes (
  poll_id text not null, unit_id text not null, choice text not null, voted_at timestamptz default now(),
  primary key (poll_id, unit_id)
);
alter table public.requests enable row level security;
alter table public.votes enable row level security;
revoke all on public.requests, public.votes from anon;
grant select, insert, update, delete on public.requests, public.votes to authenticated;
grant usage, select on sequence public.requests_id_seq to authenticated;

-- αιτήματα: ο ένοικος βλέπει/στέλνει μόνο τα δικά του, ο διαχειριστής όλα και απαντά
drop policy if exists r_sel on public.requests;
create policy r_sel on public.requests for select using (is_admin() or unit_id = my_unit());
drop policy if exists r_ins on public.requests;
create policy r_ins on public.requests for insert with check (unit_id = my_unit() and status = 'open');
drop policy if exists r_adm on public.requests;
create policy r_adm on public.requests for update using (is_admin()) with check (is_admin());
drop policy if exists r_del on public.requests;
create policy r_del on public.requests for delete using (is_admin());

-- ψηφοφορίες: όλοι βλέπουν τα αποτελέσματα, ο καθένας ψηφίζει μόνο για το διαμέρισμά του
drop policy if exists v_sel on public.votes;
create policy v_sel on public.votes for select using (has_profile());
drop policy if exists v_ins on public.votes;
create policy v_ins on public.votes for insert with check (unit_id = my_unit());
drop policy if exists v_upd on public.votes;
create policy v_upd on public.votes for update using (unit_id = my_unit()) with check (unit_id = my_unit());
drop policy if exists v_del on public.votes;
create policy v_del on public.votes for delete using (is_admin());
