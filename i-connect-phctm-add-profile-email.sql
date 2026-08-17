-- ============================================================
-- i-Connect @ PHCTM — Tambah emel pada profiles (untuk Panel Admin)
-- ============================================================

-- Tambah kolum emel
alter table profiles add column if not exists email text;

-- Isi semula emel untuk akaun yang sudah wujud
update profiles p
set email = u.email
from auth.users u
where p.id = u.id and p.email is null;

-- Kemas kini trigger supaya emel auto-terisi untuk pendaftaran akan datang
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, phone, organisation, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    new.raw_user_meta_data->>'phone',
    new.raw_user_meta_data->>'organisation',
    new.email
  );
  return new;
end;
$$ language plpgsql security definer;

-- ============================================================
-- SIAP!
-- ============================================================
