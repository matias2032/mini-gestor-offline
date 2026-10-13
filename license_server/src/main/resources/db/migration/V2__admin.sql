CREATE TABLE admin_users (
    id_admin        BIGSERIAL PRIMARY KEY,
    username        VARCHAR(50)  NOT NULL,
    password_hash   VARCHAR(100) NOT NULL,
    enabled         BOOLEAN      NOT NULL DEFAULT TRUE,
    failed_attempts INT          NOT NULL DEFAULT 0,
    locked_until    TIMESTAMPTZ,
    last_login_at   TIMESTAMPTZ,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX uq_admin_users_username ON admin_users (lower(username));

CREATE TABLE admin_audit_log (
    id_audit    BIGSERIAL PRIMARY KEY,
    admin_id    BIGINT REFERENCES admin_users (id_admin) ON DELETE SET NULL,
    username    VARCHAR(50),
    action      VARCHAR(30)  NOT NULL,
    license_id  BIGINT,
    ip          VARCHAR(45),
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_created_at ON admin_audit_log (created_at DESC);
CREATE INDEX idx_audit_license_id ON admin_audit_log (license_id);