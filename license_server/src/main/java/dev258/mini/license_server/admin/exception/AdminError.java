package dev258.mini.license_server.admin.exception;

import org.springframework.http.HttpStatus;

public enum AdminError {

    INVALID_CREDENTIALS(HttpStatus.UNAUTHORIZED),
    LOGIN_LOCKED(HttpStatus.TOO_MANY_REQUESTS),
    ADMIN_NOT_FOUND(HttpStatus.NOT_FOUND),
    WRONG_CURRENT_PASSWORD(HttpStatus.FORBIDDEN),
    WEAK_PASSWORD(HttpStatus.BAD_REQUEST),
    USERNAME_TAKEN(HttpStatus.CONFLICT);

    private final HttpStatus status;

    AdminError(HttpStatus status) {
        this.status = status;
    }

    public HttpStatus status() {
        return status;
    }

    public String code() {
        return name();
    }
}