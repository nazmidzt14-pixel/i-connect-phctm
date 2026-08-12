-- ============================================================
-- i-Connect @ PHCTM — Peraturan Akses (RLS Policies)
-- Jalankan skrip ini SELEPAS skrip pertama (database-setup.sql)
-- ============================================================

-- ----------------------------------------------------------
-- 1. PROFILES
--    - Pengguna boleh lihat & kemas kini profil sendiri sahaja
--    - Admin boleh lihat semua profil
-- ----------------------------------------------------------
create policy "Users can view own profile"
  on profiles for select
  using (auth.uid() = id);

create policy "Users can update own profile"
  on profiles for update
  using (auth.uid() = id);

create policy "Users can insert own profile"
  on profiles for insert
  with check (auth.uid() = id);

create policy "Admins can view all profiles"
  on profiles for select
  using (exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin'));

-- ----------------------------------------------------------
-- 2. SERVICES, TEAM_MEMBERS, TEAM_MEMBER_SERVICES,
--    AVAILABILITY_TEMPLATES, AVAILABILITY_OVERRIDES
--    - Direktori awam: sesiapa yang dah log masuk boleh lihat
-- ----------------------------------------------------------
create policy "Logged in users can view services"
  on services for select
  using (auth.role() = 'authenticated');

create policy "Logged in users can view team members"
  on team_members for select
  using (auth.role() = 'authenticated');

create policy "Logged in users can view team_member_services"
  on team_member_services for select
  using (auth.role() = 'authenticated');

create policy "Logged in users can view availability_templates"
  on availability_templates for select
  using (auth.role() = 'authenticated');

create policy "Logged in users can view availability_overrides"
  on availability_overrides for select
  using (auth.role() = 'authenticated');

-- ----------------------------------------------------------
-- 3. APPOINTMENTS
--    - Pengguna: urus tempahan sendiri sahaja
--    - Admin: lihat & urus semua tempahan
-- ----------------------------------------------------------
create policy "Users can view own appointments"
  on appointments for select
  using (auth.uid() = user_id);

create policy "Users can create own appointments"
  on appointments for insert
  with check (auth.uid() = user_id);

create policy "Users can update own appointments"
  on appointments for update
  using (auth.uid() = user_id);

create policy "Admins can view all appointments"
  on appointments for select
  using (exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin'));

create policy "Admins can update all appointments"
  on appointments for update
  using (exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin'));

-- ----------------------------------------------------------
-- 4. APPOINTMENT_HISTORY
--    - Pengguna boleh lihat sejarah tempahan sendiri sahaja
-- ----------------------------------------------------------
create policy "Users can view own appointment history"
  on appointment_history for select
  using (
    exists (
      select 1 from appointments a
      where a.id = appointment_history.appointment_id
      and a.user_id = auth.uid()
    )
  );

-- ----------------------------------------------------------
-- 5. AUTO-CIPTA PROFIL bila pengguna baru mendaftar
--    (Wajib — tanpa ini, borang Register takkan berfungsi)
-- ----------------------------------------------------------
create function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, phone, organisation)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    new.raw_user_meta_data->>'phone',
    new.raw_user_meta_data->>'organisation'
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ============================================================
-- SIAP! Pangkalan data anda kini selamat DAN berfungsi.
-- ============================================================
