-- EMS migration: leave management.
-- An employee submits a leave_request; an admin approves or rejects it.
-- Approved requests reduce the effective working-day denominator used by the
-- performance breakdown so the employee is not penalised for being absent.

CREATE TABLE IF NOT EXISTS leave_requests (
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
  KEY idx_leave_user    (user_id),
  KEY idx_leave_status  (status),
  KEY idx_leave_dates   (start_date, end_date),
  CONSTRAINT fk_leave_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE,
  CONSTRAINT fk_leave_decided_by
    FOREIGN KEY (decided_by) REFERENCES users(id)
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
