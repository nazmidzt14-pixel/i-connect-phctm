-- ============================================================
-- i-Connect @ PHCTM — Jadikan akaun sebagai Admin
-- Tukar emel di bawah kepada emel akaun anda sendiri
-- ============================================================

update profiles
set role = 'admin'
where id = (
  select id from auth.users
  where email = 'nazmi.idzat@hctm.ukm.edu.my'
);

-- ============================================================
-- Semak: SELECT * FROM profiles WHERE role = 'admin';
-- ============================================================
