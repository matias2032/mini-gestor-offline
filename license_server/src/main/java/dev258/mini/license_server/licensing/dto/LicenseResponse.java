package dev258.mini.license_server.licensing.dto;

import dev258.mini.license_server.licensing.entity.License;
import dev258.mini.license_server.licensing.entity.LicenseStatus;

import java.time.Instant;

public record LicenseResponse(
        Long id,
        String codeHint,
        String channel,
        String buyerLabel,
        LicenseStatus status,
        String deviceId,
        Instant activatedAt,
        int activationCount,
        Instant createdAt) {

    public static LicenseResponse from(License l) {
        return new LicenseResponse(
                l.getIdLicense(),
                l.getCodeHint(),
                l.getChannel(),
                l.getBuyerLabel(),
                l.getStatus(),
                l.getDeviceId(),
                l.getActivatedAt(),
                l.getActivationCount(),
                l.getCreatedAt());
    }
}