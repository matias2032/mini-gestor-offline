package dev258.mini.license_server.licensing.repository;

import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import dev258.mini.license_server.licensing.entity.License;

import java.util.List;
import java.util.Optional;

public interface LicenseRepository extends JpaRepository<License, Long> {

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select l from License l where l.codeHash = :codeHash")
    Optional<License> findByCodeHashForUpdate(@Param("codeHash") String codeHash);

    List<License> findByBuyerLabelContainingIgnoreCase(String buyerLabel);
}