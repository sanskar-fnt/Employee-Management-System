-- EMS migration: align attendance schema with code expectations
-- Code expects: attendance(user_id, work_date, check_in, check_out, status)
-- Existing setup.sql defines: attendance(employee_id, attendance_date, check_in_time, check_out_time, status)

-- 1) Backup table (recommended)
-- CREATE TABLE attendance_backup AS SELECT * FROM attendance;

-- 2) Add new columns (if they do not exist)
-- NOTE: MySQL does not support IF NOT EXISTS for ADD COLUMN in all versions.
-- Run these statements only if the columns are missing.
-- ALTER TABLE attendance ADD COLUMN user_id INT NULL;
-- ALTER TABLE attendance ADD COLUMN work_date DATE NULL;
-- ALTER TABLE attendance ADD COLUMN check_in TIMESTAMP NULL;
-- ALTER TABLE attendance ADD COLUMN check_out TIMESTAMP NULL;

-- 3) Migrate data
-- If attendance currently stores employee_id, map it to users via employees table
-- UPDATE attendance a
-- JOIN employees e ON e.id = a.employee_id
-- SET a.user_id = e.user_id
-- WHERE a.user_id IS NULL;

-- Copy date/time data into new columns
-- UPDATE attendance
-- SET work_date = attendance_date,
--     check_in = check_in_time,
--     check_out = check_out_time
-- WHERE work_date IS NULL;

-- 4) Enforce NOT NULL where possible (after data migration)
-- ALTER TABLE attendance MODIFY user_id INT NOT NULL;
-- ALTER TABLE attendance MODIFY work_date DATE NOT NULL;

-- 5) Add constraints and indexes
-- Ensure only one attendance row per user per day
-- ALTER TABLE attendance ADD UNIQUE KEY uniq_attendance_user_day (user_id, work_date);
-- ALTER TABLE attendance ADD INDEX idx_attendance_user_day (user_id, work_date);

-- Optional FK (aligns with code using user_id)
-- ALTER TABLE attendance
--   ADD CONSTRAINT fk_attendance_user
--   FOREIGN KEY (user_id) REFERENCES users(id)
--   ON DELETE CASCADE;

-- 6) Drop legacy columns after validation
-- ALTER TABLE attendance DROP COLUMN employee_id;
-- ALTER TABLE attendance DROP COLUMN attendance_date;
-- ALTER TABLE attendance DROP COLUMN check_in_time;
-- ALTER TABLE attendance DROP COLUMN check_out_time;
