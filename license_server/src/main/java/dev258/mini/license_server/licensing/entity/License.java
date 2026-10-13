package dev258.mini.license_server.licensing.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;

@Entity
@Table(name = "licenses")
@Getter
@Setter
public class License {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_license")
    private Long idLicense;

    @JdbcTypeCode(SqlTypes.CHAR)
    @Column(name = "code_hash", nullable = false, unique = true, length = 64)
    private String codeHash;

    @Column(name = "code_hint", nullable = false, length = 4)
    private String codeHint;

    @Column(nullable = false, length = 20)
    private String channel;

    @Column(name = "buyer_label", length = 120)
    private String buyerLabel;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 12)
    private LicenseStatus status = LicenseStatus.UNUSED;

    @Column(name = "device_id", length = 128)
    private String deviceId;

    @Column(name = "activated_at")
    private Instant activatedAt;

    @Column(name = "activation_count", nullable = false)
    private int activationCount = 0;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();
}