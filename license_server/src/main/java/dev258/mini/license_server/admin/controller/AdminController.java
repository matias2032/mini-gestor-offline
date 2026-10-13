package dev258.mini.license_server.admin.controller;

import dev258.mini.license_server.admin.dto.AdminResponse;
import dev258.mini.license_server.admin.dto.ChangePasswordRequest;
import dev258.mini.license_server.admin.dto.LoginRequest;
import dev258.mini.license_server.admin.dto.LoginResponse;
import dev258.mini.license_server.admin.dto.UpdateProfileRequest;
import dev258.mini.license_server.admin.exception.AdminException;
import dev258.mini.license_server.admin.service.AdminService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PagedModel;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class AdminController {

    private final AdminService adminService;

@PostMapping("/auth/login")
public LoginResponse login(@Valid @RequestBody LoginRequest request, HttpServletRequest http) {
    try {
        // Correção: Passar username e password separadamente
        LoginResponse response = adminService.login(request.username(), request.password());
        adminService.auditAnonymous(request.username(), "LOGIN", http.getRemoteAddr());
        return response;
    } catch (AdminException e) {
        adminService.auditAnonymous(request.username(), "LOGIN_FAILED", http.getRemoteAddr());
        throw e;
    }
}

    @GetMapping("/admin/me")
    public AdminResponse me(@AuthenticationPrincipal Jwt jwt) {
        return adminService.getProfile(adminId(jwt));
    }

    @PutMapping("/admin/me")
    public AdminResponse updateMe(@AuthenticationPrincipal Jwt jwt,
                                  @Valid @RequestBody UpdateProfileRequest request,
                                  HttpServletRequest http) {
        AdminResponse updated = adminService.updateProfile(adminId(jwt), request.username());
        adminService.audit(jwt, "PROFILE_UPDATE", null, http.getRemoteAddr());
        return updated;
    }

    @PutMapping("/admin/me/password")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void changePassword(@AuthenticationPrincipal Jwt jwt,
                               @Valid @RequestBody ChangePasswordRequest request,
                               HttpServletRequest http) {
        adminService.changePassword(adminId(jwt), request.currentPassword(), request.newPassword());
        adminService.audit(jwt, "PASSWORD_CHANGE", null, http.getRemoteAddr());
    }

    @GetMapping("/admin/audit")
    public PagedModel<AdminService.AuditEntry> audit(
            @RequestParam(required = false) Long licenseId, Pageable pageable) {
        return adminService.listAudit(licenseId, pageable);
    }

    private static Long adminId(Jwt jwt) {
        return ((Number) jwt.getClaim("adminId")).longValue();
    }
}