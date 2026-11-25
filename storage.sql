-- Αρχεία πολυκατοικίας (κανονισμός, πιστοποιητικά, πρακτικά κ.λπ.)
-- Τρέξε το ολόκληρο μία φορά στο SQL Editor του Supabase.

-- ιδιωτικός «κάδος» αρχείων: δεν ανοίγει από έξω χωρίς σύνδεση
insert into storage.buckets (id, name, public)
values ('docs', 'docs', false)
on conflict (id) do nothing;

-- όλοι οι συνδεδεμένοι (διαχειριστής και διαμερίσματα) διαβάζουν
drop policy if exists docs_read on storage.objects;
create policy docs_read on storage.objects for select to authenticated
  using (bucket_id = 'docs' and public.has_profile());

-- μόνο ο διαχειριστής ανεβάζει, αλλάζει, σβήνει
drop policy if exists docs_ins on storage.objects;
create policy docs_ins on storage.objects for insert to authenticated
  with check (bucket_id = 'docs' and public.is_admin());
drop policy if exists docs_upd on storage.objects;
create policy docs_upd on storage.objects for update to authenticated
  using (bucket_id = 'docs' and public.is_admin());
drop policy if exists docs_del on storage.objects;
create policy docs_del on storage.objects for delete to authenticated
  using (bucket_id = 'docs' and public.is_admin());
