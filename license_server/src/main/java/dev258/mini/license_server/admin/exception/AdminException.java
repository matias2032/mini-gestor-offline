package dev258.mini.license_server.admin.exception;

import dev258.mini.license_server.common.exception.ApiException;

public class AdminException extends ApiException {

    public AdminException(AdminError error) {
        super(error.status(), error.code());
    }
}