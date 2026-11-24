-- Κοινόχρηστα πολυκατοικίας – βάση δεδομένων Supabase
-- Τρέξε το ολόκληρο μία φορά: Supabase → SQL Editor → New query → επικόλληση → Run

create table if not exists public.profiles (
  user_id  uuid primary key references auth.users on delete cascade,
  username text unique not null,
  role     text not null check (role in ('admin','unit')),
  unit_id  text
);
create table if not exists public.app_state (            -- όλα τα δεδομένα· μόνο ο διαχειριστής
  id int primary key default 1, data jsonb, updated_at timestamptz default now()
);
create table if not exists public.unit_cards (           -- η καρτέλα κάθε διαμερίσματος
  unit_id text primary key, data jsonb, updated_at timestamptz default now()
);
create table if not exists public.public_info (          -- ανακοινώσεις, IBAN, δαπάνες κτιρίου
  id int primary key default 1, data jsonb, updated_at timestamptz default now()
);

-- πρόσβαση μέσω API μόνο για συνδεδεμένους χρήστες (οι κανόνες RLS παρακάτω ορίζουν τι βλέπει ο καθένας)
revoke all on public.profiles, public.app_state, public.unit_cards, public.public_info from anon;
grant usage on schema public to authenticated;
grant select, insert, update, delete on public.profiles, public.app_state, public.unit_cards, public.public_info to authenticated;

alter table public.profiles    enable row level security;
alter table public.app_state   enable row level security;
alter table public.unit_cards  enable row level security;
alter table public.public_info enable row level security;

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from profiles where user_id = auth.uid() and role = 'admin')
$$;
create or replace function public.my_unit() returns text
language sql stable security definer set search_path = public as $$
  select unit_id from profiles where user_id = auth.uid()
$$;
create or replace function public.has_profile() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from profiles where user_id = auth.uid())
$$;

grant execute on function public.is_admin(), public.my_unit(), public.has_profile() to authenticated;

-- profiles: ο καθένας βλέπει τον εαυτό του, ο διαχειριστής όλους
drop policy if exists p_sel on public.profiles;
create policy p_sel on public.profiles for select using (user_id = auth.uid() or is_admin());
drop policy if exists p_adm on public.profiles;
create policy p_adm on public.profiles for all using (is_admin()) with check (is_admin());

-- app_state: μόνο διαχειριστής
drop policy if exists s_adm on public.app_state;
create policy s_adm on public.app_state for all using (is_admin()) with check (is_admin());

-- unit_cards: κάθε διαμέρισμα ΜΟΝΟ τη δική του καρτέλα
drop policy if exists c_sel on public.unit_cards;
create policy c_sel on public.unit_cards for select using (is_admin() or unit_id = my_unit());
drop policy if exists c_adm on public.unit_cards;
create policy c_adm on public.unit_cards for all using (is_admin()) with check (is_admin());

-- public_info: όλοι οι συνδεδεμένοι ένοικοι διαβάζουν, γράφει ο διαχειριστής
drop policy if exists i_sel on public.public_info;
create policy i_sel on public.public_info for select using (has_profile());
drop policy if exists i_adm on public.public_info;
create policy i_adm on public.public_info for all using (is_admin()) with check (is_admin());

-- ΜΕΤΑ: φτιάξε τον λογαριασμό σου στο Authentication → Users → Add user
--   email: admin@polykatoikia.app  (ή το δικό σου email), κωδικός, «Auto Confirm User»
-- και τρέξε (άλλαξε το email αν έβαλες άλλο):
-- insert into public.profiles (user_id, username, role)
--   select id, 'admin', 'admin' from auth.users where email = 'admin@polykatoikia.app';
