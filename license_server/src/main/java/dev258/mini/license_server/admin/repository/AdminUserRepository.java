package dev258.mini.license_server.admin.repository;

import dev258.mini.license_server.admin.entity.AdminUser;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface AdminUserRepository extends JpaRepository<AdminUser, Long> {

    Optional<AdminUser> findByUsernameIgnoreCase(String username);
}