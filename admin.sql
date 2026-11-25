-- Νέος κωδικός σε λογαριασμό διαμερίσματος από την εφαρμογή (μόνο ο διαχειριστής)
create extension if not exists pgcrypto with schema extensions;
create or replace function public.admin_set_password(p_username text, p_password text) returns void
language plpgsql security definer set search_path = public, extensions as $$
declare v uuid;
begin
  if not is_admin() then raise exception 'Μόνο ο διαχειριστής'; end if;
  if length(p_password) < 6 then raise exception 'Ο κωδικός θέλει τουλάχιστον 6 χαρακτήρες'; end if;
  select user_id into v from profiles where username = p_username;
  if v is null then raise exception 'Δεν βρέθηκε ο χρήστης'; end if;
  update auth.users set encrypted_password = extensions.crypt(p_password, extensions.gen_salt('bf')),
    raw_user_meta_data = coalesce(raw_user_meta_data, '{}'::jsonb) - 'pwchanged', updated_at = now() where id = v;
end $$;
revoke all on function public.admin_set_password(text, text) from public, anon;
grant execute on function public.admin_set_password(text, text) to authenticated;
