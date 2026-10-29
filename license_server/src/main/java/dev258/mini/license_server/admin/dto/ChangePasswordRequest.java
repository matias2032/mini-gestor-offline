package dev258.mini.license_server.admin.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ChangePasswordRequest(
        @NotBlank @Size(max = 100) String currentPassword,
        @NotBlank @Size(max = 100) String newPassword) {

    @Override
    public String toString() {
        return "ChangePasswordRequest[]";
    }
}