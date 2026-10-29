package dev258.mini.license_server.licensing.controller;

import dev258.mini.license_server.admin.service.AdminService;
import dev258.mini.license_server.licensing.dto.ActivateRequest;
import dev258.mini.license_server.licensing.dto.GenerateRequest;
import dev258.mini.license_server.licensing.dto.LicenseResponse;
import dev258.mini.license_server.licensing.service.LicenseService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import dev258.mini.license_server.licensing.entity.LicenseStatus;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PagedModel;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class LicenseController {

    private final LicenseService service;
    private final AdminService adminService;

    // ---------- publico ----------

    @PostMapping("/licenses/activate")
    public LicenseService.SignedLicense activate(@Valid @RequestBody ActivateRequest request) {
        return service.activate(request.code(), request.deviceId());
    }

    // ---------- admin (exige JWT, definido no SecurityConfig) ----------

    @PostMapping("/admin/licenses")
    @ResponseStatus(HttpStatus.CREATED)
    public LicenseService.GeneratedLicense generate(@Valid @RequestBody GenerateRequest request,
                                                    @AuthenticationPrincipal Jwt jwt,
                                                    HttpServletRequest http) {
        LicenseService.GeneratedLicense created = service.generate(request.channel(), request.buyerLabel());
        adminService.audit(jwt, "LICENSE_GENERATE", created.id(), http.getRemoteAddr());
        return created;
    }

    @GetMapping("/admin/licenses")
    public PagedModel<LicenseResponse> list(@RequestParam(required = false) String buyer,
                                            @RequestParam(required = false) LicenseStatus status,
                                            @RequestParam(required = false) String channel,
                                            Pageable pageable) {
        return new PagedModel<>(service.search(buyer, status, channel, pageable)
                .map(LicenseResponse::from));
    }

    @GetMapping("/admin/licenses/{id}")
    public LicenseResponse get(@PathVariable Long id) {
        return LicenseResponse.from(service.get(id));
    }

    @PostMapping("/admin/licenses/{id}/reset")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void reset(@PathVariable Long id, @AuthenticationPrincipal Jwt jwt, HttpServletRequest http) {
        service.reset(id);
        adminService.audit(jwt, "LICENSE_RESET", id, http.getRemoteAddr());
    }

    @PostMapping("/admin/licenses/{id}/revoke")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void revoke(@PathVariable Long id, @AuthenticationPrincipal Jwt jwt, HttpServletRequest http) {
        service.revoke(id);
        adminService.audit(jwt, "LICENSE_REVOKE", id, http.getRemoteAddr());
    }
}