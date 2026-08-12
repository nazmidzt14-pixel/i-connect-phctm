-- ============================================================
-- i-Connect @ PHCTM — Skrip Persediaan Pangkalan Data
-- Jalankan skrip ini SEKALI sahaja dalam Supabase SQL Editor
-- ============================================================

-- Lanjutan (extension) diperlukan untuk jana ID rawak (UUID)
create extension if not exists pgcrypto;

-- ----------------------------------------------------------
-- 1. PROFILES — maklumat tambahan pengguna (sambung dgn Supabase Auth)
-- ----------------------------------------------------------
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  phone text,
  organisation text,
  role text not null default 'user' check (role in ('user','pic','admin')),
  created_at timestamptz not null default now()
);

-- ----------------------------------------------------------
-- 2. SERVICES — tiga servis rasmi
-- ----------------------------------------------------------
create table services (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name text not null,
  description_en text,
  description_ms text,
  created_at timestamptz not null default now()
);

insert into services (slug, name, description_en, description_ms) values
('penerbitan', 'Perundingan Penerbitan',
 'Consultation on journals, proceedings, books, book chapters, policy papers, technical/research reports, seminar material, and monographs.',
 'Khidmat runding berkaitan jurnal, prosiding, buku, bab buku, kertas polisi, laporan teknikal/penyelidikan, bahan seminar, dan monograf.'),
('esumber', 'e-Sumber@PTSL',
 'Consultation on databases, eBooks, eJournals, and UKM electronic resources.',
 'Khidmat runding berkaitan pangkalan data, eBook, eJurnal, dan sumber elektronik UKM.'),
('kursus', 'Kursus Kemahiran Maklumat',
 'Training on EndNote, Mendeley bibliography management, and medical information searching.',
 'Latihan pengurusan bibliografi EndNote, Mendeley, dan pencarian maklumat perubatan.');

-- ----------------------------------------------------------
-- 3. TEAM_MEMBERS — pegawai perpustakaan
-- ----------------------------------------------------------
create table team_members (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name text not null,
  position_en text,
  position_ms text,
  email text not null,
  phone text,
  expertise_en text,
  expertise_ms text,
  created_at timestamptz not null default now()
);

insert into team_members (slug, name, position_en, position_ms, email, phone, expertise_en, expertise_ms) values
('hafiz', 'TS. Md Hafiz Ahmad Zulkifli', 'Senior Librarian', 'Pustakawan Kanan', 'hafiz_az@ukm.edu.my', '03-9145 5336', 'All publication categories', 'Semua kategori penerbitan'),
('afifah', 'Wan Nur ''Afifah Wan Yahya', 'Librarian', 'Pustakawan', 'afifahyahya@hctm.ukm.edu.my', '03-9145 5335', 'Journals, Proceedings', 'Jurnal, Prosiding'),
('nazmi', 'Mohd Nazmi Idzat Mohamad Aizal', 'Library Assistant', 'Pembantu Pustakawan', 'nazmi.idzat@hctm.ukm.edu.my', '03-9145 6346', 'All publication types except Journals & Proceedings', 'Semua jenis penerbitan selain Jurnal & Prosiding'),
('qurratul', 'Qurratul Syaheera Ahmad Termizi', 'Librarian', 'Pustakawan', 'qurratulsyaheera@hctm.ukm.edu.my', '03-9145 5337', 'e-Resources & Information Skills training', 'Latihan e-Sumber & Kemahiran Maklumat'),
('adilla', 'Adilla Mohmaddun', 'Assistant Librarian', 'Penolong Pustakawan', 'adilla.mohmaddun@hctm.ukm.edu.my', '03-9145 6346', 'Information Skills training', 'Latihan Kemahiran Maklumat');

-- ----------------------------------------------------------
-- 4. TEAM_MEMBER_SERVICES — pautan pegawai <-> servis (many-to-many)
-- ----------------------------------------------------------
create table team_member_services (
  team_member_id uuid references team_members(id) on delete cascade,
  service_id uuid references services(id) on delete cascade,
  primary key (team_member_id, service_id)
);

insert into team_member_services (team_member_id, service_id)
select tm.id, s.id from team_members tm, services s
where (tm.slug='hafiz'    and s.slug in ('penerbitan','esumber'))
   or (tm.slug='afifah'   and s.slug='penerbitan')
   or (tm.slug='nazmi'    and s.slug='penerbitan')
   or (tm.slug='qurratul' and s.slug in ('esumber','kursus'))
   or (tm.slug='adilla'   and s.slug='kursus');

-- ----------------------------------------------------------
-- 5. AVAILABILITY_TEMPLATES — waktu bekerja lalai (default) setiap pegawai
--    (Isnin-Jumaat, 9:00 pagi - 5:00 petang, slot 30 minit)
-- ----------------------------------------------------------
create table availability_templates (
  id uuid primary key default gen_random_uuid(),
  team_member_id uuid references team_members(id) on delete cascade,
  day_of_week int not null check (day_of_week between 1 and 5), -- 1=Isnin ... 5=Jumaat
  start_time time not null default '09:00',
  end_time time not null default '17:00',
  slot_duration_minutes int not null default 30
);

insert into availability_templates (team_member_id, day_of_week, start_time, end_time, slot_duration_minutes)
select tm.id, d, '09:00', '17:00', 30
from team_members tm, generate_series(1,5) as d;

-- ----------------------------------------------------------
-- 6. AVAILABILITY_OVERRIDES — cuti / hari khas setiap pegawai
-- ----------------------------------------------------------
create table availability_overrides (
  id uuid primary key default gen_random_uuid(),
  team_member_id uuid references team_members(id) on delete cascade,
  date date not null,
  is_available boolean not null default false,
  start_time time,
  end_time time,
  reason text
);

-- ----------------------------------------------------------
-- 7. APPOINTMENTS — tempahan sebenar
--    (unique constraint elak double-booking slot yang sama)
-- ----------------------------------------------------------
create table appointments (
  id uuid primary key default gen_random_uuid(),
  booking_ref text unique not null default ('BK-' || to_char(now(),'YYYYMMDD') || '-' || substr(gen_random_uuid()::text,1,6)),
  user_id uuid references profiles(id) on delete cascade,
  service_id uuid references services(id),
  team_member_id uuid references team_members(id),
  appointment_type text not null check (appointment_type in ('Bersemuka','Online Video')),
  appointment_date date not null,
  appointment_time time not null,
  status text not null default 'Upcoming' check (status in ('Upcoming','Completed','Cancelled','Rescheduled')),
  purpose text,
  meeting_link text,
  meeting_link_status text default 'pending' check (meeting_link_status in ('pending','added','not_applicable')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (team_member_id, appointment_date, appointment_time)
);

-- ----------------------------------------------------------
-- 8. APPOINTMENT_HISTORY — rekod audit (jadual semula/batal)
-- ----------------------------------------------------------
create table appointment_history (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid references appointments(id) on delete cascade,
  changed_field text not null,
  old_value text,
  new_value text,
  changed_by uuid,
  changed_at timestamptz not null default now()
);

-- ----------------------------------------------------------
-- 9. NOTIFICATIONS — log emel yang dihantar
-- ----------------------------------------------------------
create table notifications (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid references appointments(id) on delete cascade,
  type text not null check (type in ('confirmation','reminder','link_added','cancelled','rescheduled')),
  recipient text not null,
  sent_at timestamptz
);

-- ============================================================
-- SIAP! Semak jadual anda di menu "Table Editor" (ikon grid)
-- di sebelah kiri Supabase selepas skrip ini berjaya dijalankan.
-- ============================================================
