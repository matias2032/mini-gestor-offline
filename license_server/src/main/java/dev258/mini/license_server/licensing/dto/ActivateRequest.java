package dev258.mini.license_server.licensing.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ActivateRequest(
        @NotBlank @Size(max = 64) String code,
        @NotBlank @Size(max = 128) String deviceId) {
}