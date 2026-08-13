-- ============================================================
-- i-Connect @ PHCTM — Kemas kini waktu asas perpustakaan
-- Daripada 9:00 pagi - 5:00 petang  KEPADA  8:30 pagi - 6:00 petang
-- ============================================================

update availability_templates
set start_time = '08:30',
    end_time   = '18:00';

-- ============================================================
-- SIAP! Ini waktu ASAS sahaja (isnin-jumaat, semua PIC).
-- Waktu individu setiap PIC akan kita laraskan lepas anda
-- pilih cara mana (PIC urus sendiri / Admin urus berpusat).
-- ============================================================
