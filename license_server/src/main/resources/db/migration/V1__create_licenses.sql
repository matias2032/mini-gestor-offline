
CREATE TABLE licenses (
    id_license               BIGSERIAL PRIMARY KEY,
    code_hash        CHAR(64)     NOT NULL UNIQUE,
    code_hint        VARCHAR(4)   NOT NULL,
    channel          VARCHAR(20)  NOT NULL,
    buyer_label      VARCHAR(120),
    status           VARCHAR(12)  NOT NULL DEFAULT 'UNUSED'
        CONSTRAINT chk_licenses_status
        CHECK (status IN ('UNUSED', 'ACTIVE', 'REVOKED')),
    device_id        VARCHAR(128),
    activated_at     TIMESTAMPTZ,
    activation_count INT          NOT NULL DEFAULT 0,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX idx_licenses_buyer_label ON licenses (lower(buyer_label));