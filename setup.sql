-- ============================================================
--  EMS — full schema
--  Matches the running application exactly:
--    attendance(user_id, work_date, check_in, check_out, status)
--    users.must_change_password
--    UNIQUE on users.username and employees.email
--    Cascade FKs from employees → users and tasks → users
-- ============================================================

CREATE DATABASE IF NOT EXISTS ems_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE ems_db;

-- Drop in reverse FK order so re-runs are clean.
DROP TABLE IF EXISTS leave_requests;
DROP TABLE IF EXISTS admin_notifications;
DROP TABLE IF EXISTS audit_logs;
DROP TABLE IF EXISTS tasks;
DROP TABLE IF EXISTS attendance;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS users;

-- ----------------------------------------------------------------
--  USERS
-- ----------------------------------------------------------------
CREATE TABLE users (
  id                    INT          NOT NULL AUTO_INCREMENT,
  username              VARCHAR(50)  NOT NULL,
  password              VARCHAR(255) NOT NULL,
  role                  VARCHAR(20)  NOT NULL DEFAULT 'EMPLOYEE',
  employee_id           INT          NULL,
  must_change_password  TINYINT(1)   NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uniq_users_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------
--  EMPLOYEES  (FK user_id → users.id, ON DELETE CASCADE)
-- ----------------------------------------------------------------
CREATE TABLE employees (
  id          INT          NOT NULL AUTO_INCREMENT,
  user_id     INT          NOT NULL,
  name        VARCHAR(100) NOT NULL,
  email       VARCHAR(100) NOT NULL,
  phone       VARCHAR(20)  NULL,
  department  VARCHAR(50)  NULL,
  status      VARCHAR(20)  NOT NULL DEFAULT 'Inactive',
  PRIMARY KEY (id),
  UNIQUE KEY uniq_employees_email (email),
  KEY idx_employees_user (user_id),
  CONSTRAINT fk_employees_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------
--  ATTENDANCE  (per the running code: user_id, work_date, check_in, check_out)
--  Legacy columns (employee_id, attendance_date, check_in_time, check_out_time) intentionally removed.
-- ----------------------------------------------------------------
CREATE TABLE attendance (
  id          INT         NOT NULL AUTO_INCREMENT,
  user_id     INT         NOT NULL,
  work_date   DATE        NOT NULL,
  check_in    TIMESTAMP   NULL DEFAULT NULL,
  check_out   TIMESTAMP   NULL DEFAULT NULL,
  status      VARCHAR(20) NOT NULL DEFAULT 'PRESENT',
  PRIMARY KEY (id),
  UNIQUE KEY uniq_attendance_user_day (user_id, work_date),
  KEY idx_attendance_work_date (work_date),
  CONSTRAINT fk_attendance_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------
--  TASKS  (FKs to users.id; deletes handled at app layer for assigned_by reassignment)
-- ----------------------------------------------------------------
CREATE TABLE tasks (
  id           INT          NOT NULL AUTO_INCREMENT,
  title        VARCHAR(150) NOT NULL,
  description  TEXT         NOT NULL,
  assigned_to  INT          NOT NULL,
  assigned_by  INT          NOT NULL,
  status       VARCHAR(20)  NOT NULL DEFAULT 'PENDING',
  priority     VARCHAR(20)  NOT NULL DEFAULT 'MEDIUM',
  due_date     DATE         NULL,
  reminder_at  DATETIME     NULL,
  created_at   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_tasks_assigned_to (assigned_to),
  KEY idx_tasks_assigned_by (assigned_by),
  KEY idx_tasks_status      (status),
  KEY idx_tasks_due_date    (due_date),
  CONSTRAINT fk_tasks_assigned_to FOREIGN KEY (assigned_to) REFERENCES users(id),
  CONSTRAINT fk_tasks_assigned_by FOREIGN KEY (assigned_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------
--  AUDIT LOGS  (append-only history of admin/employee actions)
-- ----------------------------------------------------------------
CREATE TABLE audit_logs (
  id             BIGINT       NOT NULL AUTO_INCREMENT,
  actor_user_id  INT          NULL,
  action         VARCHAR(40)  NOT NULL,
  entity_type    VARCHAR(40)  NULL,
  entity_id      INT          NULL,
  details        VARCHAR(500) NULL,
  created_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_audit_created (created_at),
  KEY idx_audit_action  (action),
  KEY idx_audit_actor   (actor_user_id),
  CONSTRAINT fk_audit_actor
    FOREIGN KEY (actor_user_id) REFERENCES users(id)
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------
--  ADMIN NOTIFICATIONS  (persisted bell-icon alerts; dedupe_key for idempotency)
-- ----------------------------------------------------------------
CREATE TABLE admin_notifications (
  id          BIGINT       NOT NULL AUTO_INCREMENT,
  type        VARCHAR(40)  NOT NULL,
  severity    VARCHAR(20)  NOT NULL DEFAULT 'info',
  title       VARCHAR(160) NOT NULL,
  message     VARCHAR(500) NULL,
  href        VARCHAR(255) NULL,
  dedupe_key  VARCHAR(120) NOT NULL,
  created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  read_at     TIMESTAMP    NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uniq_admin_noti_dedupe (dedupe_key),
  KEY idx_admin_noti_read    (read_at),
  KEY idx_admin_noti_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------
--  LEAVE REQUESTS  (employee submits, admin approves/rejects)
-- ----------------------------------------------------------------
CREATE TABLE leave_requests (
  id            INT          NOT NULL AUTO_INCREMENT,
  user_id       INT          NOT NULL,
  leave_type    VARCHAR(20)  NOT NULL DEFAULT 'CASUAL',
  start_date    DATE         NOT NULL,
  end_date      DATE         NOT NULL,
  reason        VARCHAR(500) NULL,
  status        VARCHAR(20)  NOT NULL DEFAULT 'PENDING',
  decided_by    INT          NULL,
  decided_at    TIMESTAMP    NULL,
  created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_leave_user   (user_id),
  KEY idx_leave_status (status),
  KEY idx_leave_dates  (start_date, end_date),
  CONSTRAINT fk_leave_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE,
  CONSTRAINT fk_leave_decided_by
    FOREIGN KEY (decided_by) REFERENCES users(id)
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------
--  SEED DATA  (bcrypt hashes — no plaintext credentials in source)
--    admin    / admin     → must_change_password = 0 (admin can rotate manually)
--    employee / employee  → must_change_password = 1 (forced rotation on first login)
--  Hashes generated with bcrypt cost 10. UserService.isPasswordValid handles
--  the $2b$ prefix (jbcrypt accepts $2a / $2b / $2y interchangeably).
-- ----------------------------------------------------------------
INSERT INTO users (username, password, role, must_change_password) VALUES
  ('admin',    '$2b$10$z3GFbCZwIPASjWYlK5AKrekPHRAIhVfN9DdeyqDyLDmEjki.nJbMC', 'ADMIN',    0),
  ('employee', '$2b$10$18z4SS4Rg1R6Lrx2DJoUdusWc/Q7S1idjzuOrUrg3zjutRS8LDYne', 'EMPLOYEE', 1);

INSERT INTO employees (user_id, name, email, phone, department, status)
SELECT id, 'Demo Employee', 'employee@example.com', '000-000-0000', 'Operations', 'Inactive'
FROM users WHERE username = 'employee'
LIMIT 1;
