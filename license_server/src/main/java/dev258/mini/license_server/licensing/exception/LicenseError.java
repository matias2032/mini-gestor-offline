package dev258.mini.license_server.licensing.exception;

import lombok.Getter;
import org.springframework.http.HttpStatus;

@Getter
public enum LicenseError {
    INVALID_CODE(HttpStatus.NOT_FOUND),
    ALREADY_USED(HttpStatus.CONFLICT),
    REVOKED(HttpStatus.FORBIDDEN);

    private final HttpStatus status;

    LicenseError(HttpStatus status) {
        this.status = status;
    }
}