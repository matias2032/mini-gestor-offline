package dev258.mini.license_server.admin.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

@Entity
@Table(name = "admin_audit_log")
@Getter
@Setter
public class AdminAuditLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_audit")
    private Long idAudit;

    @Column(name = "admin_id")
    private Long adminId;

    @Column(length = 50)
    private String username;

    @Column(nullable = false, length = 30)
    private String action;

    @Column(name = "license_id")
    private Long licenseId;

    @Column(length = 45)
    private String ip;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();
}