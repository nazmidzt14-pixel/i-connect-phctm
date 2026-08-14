-- ============================================================
-- i-Connect @ PHCTM — Betulkan bug "infinite recursion" RLS
-- ============================================================

-- 1. Buang peraturan lama yang bermasalah (semak diri sendiri = gelung tanpa henti)
drop policy if exists "Admins can view all profiles" on profiles;
drop policy if exists "Admins can view all appointments" on appointments;
drop policy if exists "Admins can update all appointments" on appointments;

-- 2. Cipta fungsi khas untuk semak "adakah pengguna ini admin?"
--    (SECURITY DEFINER = fungsi ini "memintas" RLS semasa ia sendiri
--    menyemak jadual profiles, jadi tiada lagi gelung tanpa henti)
create or replace function public.is_admin()
returns boolean
language sql security definer
set search_path = public
as $$
  select exists(
    select 1 from profiles where id = auth.uid() and role = 'admin'
  );
$$;

-- 3. Cipta semula peraturan admin, kali ini guna fungsi tadi (SELAMAT, tiada gelung)
create policy "Admins can view all profiles"
  on profiles for select
  using (public.is_admin());

create policy "Admins can view all appointments"
  on appointments for select
  using (public.is_admin());

create policy "Admins can update all appointments"
  on appointments for update
  using (public.is_admin());

-- ============================================================
-- SIAP! Cuba buat tempahan sekali lagi selepas ini.
-- ============================================================
