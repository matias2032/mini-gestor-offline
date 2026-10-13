package dev258.mini.license_server.admin.repository;

import dev258.mini.license_server.admin.entity.AdminAuditLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AdminAuditRepository extends JpaRepository<AdminAuditLog, Long> {

    Page<AdminAuditLog> findAllByOrderByCreatedAtDesc(Pageable pageable);

    Page<AdminAuditLog> findByLicenseIdOrderByCreatedAtDesc(Long licenseId, Pageable pageable);
}