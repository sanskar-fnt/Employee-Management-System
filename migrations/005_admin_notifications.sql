-- EMS migration: persisted admin notifications.
-- dedupe_key gives idempotency so the periodic scans (overdue tasks, missed
-- check-out, low attendance) cannot insert the same alert twice.

CREATE TABLE IF NOT EXISTS admin_notifications (
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
