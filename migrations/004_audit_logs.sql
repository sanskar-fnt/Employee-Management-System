-- EMS migration: audit log table.
--
-- Append-only record of admin/employee actions for compliance + admin review.
-- actor_user_id is nullable so anonymous events (e.g. failed logins) can still be logged.

CREATE TABLE IF NOT EXISTS audit_logs (
  id             BIGINT       NOT NULL AUTO_INCREMENT,
  actor_user_id  INT          NULL,
  action         VARCHAR(40)  NOT NULL,
  entity_type    VARCHAR(40)  NULL,
  entity_id      INT          NULL,
  details        VARCHAR(500) NULL,
  created_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_audit_created    (created_at),
  KEY idx_audit_action     (action),
  KEY idx_audit_actor      (actor_user_id),
  CONSTRAINT fk_audit_actor
    FOREIGN KEY (actor_user_id) REFERENCES users(id)
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
