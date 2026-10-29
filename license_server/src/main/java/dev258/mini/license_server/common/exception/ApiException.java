package dev258.mini.license_server.common.exception;

import lombok.Getter;
import org.springframework.http.HttpStatus;

@Getter
public class ApiException extends RuntimeException {

    private final HttpStatus status;
    private final String code;

    public ApiException(HttpStatus status, String code) {
        super(code, null, false, false);
        this.status = status;
        this.code = code;
    }
}