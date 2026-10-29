package dev258.mini.license_server.admin.dto;

public record LoginResponse(String token, String tokenType, long expiresIn) {
}