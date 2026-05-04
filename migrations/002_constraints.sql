-- EMS constraints for uniqueness and relationships
-- Run after cleaning duplicates if any.

-- 1) Ensure usernames are unique
-- Check duplicates:
-- SELECT username, COUNT(*) FROM users GROUP BY username HAVING COUNT(*) > 1;
-- Apply constraint:
-- ALTER TABLE users ADD UNIQUE KEY uniq_users_username (username);

-- 2) Ensure employee emails are unique
-- Check duplicates:
-- SELECT email, COUNT(*) FROM employees GROUP BY email HAVING COUNT(*) > 1;
-- Apply constraint:
-- ALTER TABLE employees ADD UNIQUE KEY uniq_employees_email (email);

-- 3) Optional FK from employees.user_id to users.id
-- Ensure there are no orphans:
-- SELECT e.id FROM employees e LEFT JOIN users u ON u.id = e.user_id WHERE u.id IS NULL;
-- Apply constraint:
-- ALTER TABLE employees
--   ADD CONSTRAINT fk_employees_user
--   FOREIGN KEY (user_id) REFERENCES users(id)
--   ON DELETE CASCADE;
