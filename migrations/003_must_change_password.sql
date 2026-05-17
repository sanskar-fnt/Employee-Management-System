-- EMS migration: enforce first-login password change for new employees.
--
-- Run this once against ems_db. After running, all freshly-onboarded employees
-- will be created with must_change_password = 1 and must reset on first login.
-- Existing accounts default to 0 so they keep working as before.

ALTER TABLE users
  ADD COLUMN must_change_password TINYINT(1) NOT NULL DEFAULT 0;

-- Optional: force everyone except the seeded admin to reset on next login.
-- UPDATE users SET must_change_password = 1 WHERE role = 'EMPLOYEE';
