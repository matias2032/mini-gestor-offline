package dev258.mini.license_server.licensing.exception;

import dev258.mini.license_server.common.exception.ApiException;

public class LicenseException extends ApiException {

    public LicenseException(LicenseError error) {
        super(error.getStatus(), error.name());
    }
}