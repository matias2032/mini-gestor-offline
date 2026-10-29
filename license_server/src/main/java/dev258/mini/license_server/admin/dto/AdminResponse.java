package dev258.mini.license_server.admin.dto;

import java.time.Instant;

public record AdminResponse(Long id, String username, Instant lastLoginAt, Instant createdAt) {
}