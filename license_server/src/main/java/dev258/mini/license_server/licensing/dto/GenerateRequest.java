package dev258.mini.license_server.licensing.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record GenerateRequest(
        @NotBlank @Size(max = 20) String channel,
        @Size(max = 120) String buyerLabel) {
}