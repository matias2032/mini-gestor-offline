package dev258.mini.license_server.admin.service;

import dev258.mini.license_server.admin.dto.AdminResponse;
import dev258.mini.license_server.admin.dto.LoginResponse;
import dev258.mini.license_server.admin.entity.AdminUser;
import dev258.mini.license_server.admin.exception.AdminError;
import dev258.mini.license_server.admin.exception.AdminException;
import dev258.mini.license_server.admin.repository.AdminUserRepository;
import com.nimbusds.jose.jwk.source.ImmutableSecret;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import dev258.mini.license_server.admin.entity.AdminAuditLog;
import dev258.mini.license_server.admin.repository.AdminAuditRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PagedModel;
import org.springframework.security.oauth2.jwt.Jwt;

import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;

@Slf4j
@Service
public class AdminService implements ApplicationRunner {

    private static final int MIN_PASSWORD_LENGTH = 12;
    private static final int MAX_FAILED_ATTEMPTS = 5;
    private static final Duration LOCK_DURATION = Duration.ofMinutes(15);
    private static final int MIN_SECRET_BYTES = 32;
    public static final String ISSUER = "license-server";

    private final AdminUserRepository repository;
    private final PasswordEncoder passwordEncoder;
    private final JwtEncoder jwtEncoder;
    private final Duration tokenTtl;
    private final String dummyHash;
    private final String bootstrapUsername;
    private final String bootstrapPassword;
    private final AdminAuditRepository auditRepository;
    
    public AdminService(AdminUserRepository repository,
                        PasswordEncoder passwordEncoder,
                        AdminAuditRepository auditRepository,
                        @Value("${admin.jwt.secret:}") String secret,
                        @Value("${admin.jwt.ttl-minutes:30}") long ttlMinutes,
                        @Value("${admin.bootstrap.username:}") String bootstrapUsername,
                        @Value("${admin.bootstrap.password:}") String bootstrapPassword) {
        byte[] key = secret.getBytes(StandardCharsets.UTF_8);
        if (key.length < MIN_SECRET_BYTES) {
            throw new IllegalStateException(
                    "admin.jwt.secret deve ter pelo menos " + MIN_SECRET_BYTES + " bytes");
        }
        if (ttlMinutes < 1) {
            throw new IllegalStateException("admin.jwt.ttl-minutes deve ser >= 1");
        }
        this.repository = repository;
        this.passwordEncoder = passwordEncoder;
        this.auditRepository = auditRepository;
        this.jwtEncoder = new NimbusJwtEncoder(
                new ImmutableSecret<>(new SecretKeySpec(key, "HmacSHA256")));
        this.tokenTtl = Duration.ofMinutes(ttlMinutes);
        this.dummyHash = passwordEncoder.encode("dummy-password-for-timing");
        this.bootstrapUsername = bootstrapUsername;
        this.bootstrapPassword = bootstrapPassword;
    }

    // ---------- bootstrap ----------

    @Override
    public void run(ApplicationArguments args) {
        if (repository.count() > 0) {
            return;
        }
        if (bootstrapUsername.isBlank() || bootstrapPassword.isBlank()) {
            log.warn("Nao existe nenhum admin e admin.bootstrap.* esta vazio: o painel nao tera login");
            return;
        }
        if (bootstrapUsername.trim().length() > 50) {
            throw new IllegalStateException("admin.bootstrap.username excede 50 caracteres");
        }
        requireStrongPassword(bootstrapPassword, true);
        AdminUser admin = new AdminUser();
        admin.setUsername(bootstrapUsername.trim());
        admin.setPasswordHash(passwordEncoder.encode(bootstrapPassword));
        repository.save(admin);
        log.info("Admin inicial criado: {}", admin.getUsername());
    }

    // ---------- login ----------

    @Transactional(noRollbackFor = AdminException.class)
    public LoginResponse login(String username, String password) {
        Instant now = Instant.now();

        AdminUser admin = repository.findByUsernameIgnoreCase(username.trim()).orElse(null);
        if (admin == null || !admin.isEnabled()) {
            passwordEncoder.matches(password, dummyHash);
            throw new AdminException(AdminError.INVALID_CREDENTIALS);
        }

        if (admin.getLockedUntil() != null) {
            if (admin.getLockedUntil().isAfter(now)) {
                throw new AdminException(AdminError.LOGIN_LOCKED);
            }
            admin.setLockedUntil(null);
            admin.setFailedAttempts(0);
        }

        if (!passwordEncoder.matches(password, admin.getPasswordHash())) {
            int attempts = admin.getFailedAttempts() + 1;
            admin.setFailedAttempts(attempts);
            if (attempts >= MAX_FAILED_ATTEMPTS) {
                admin.setLockedUntil(now.plus(LOCK_DURATION));
                log.warn("Admin '{}' bloqueado ate {}", admin.getUsername(), admin.getLockedUntil());
            }
            throw new AdminException(AdminError.INVALID_CREDENTIALS);
        }

        admin.setFailedAttempts(0);
        admin.setLockedUntil(null);
        admin.setLastLoginAt(now);

        return new LoginResponse(issueToken(admin, now), "Bearer", tokenTtl.toSeconds());
    }

    // ---------- perfil e password ----------

    @Transactional(readOnly = true)
    public AdminResponse getProfile(Long idAdmin) {
        return toResponse(find(idAdmin));
    }

    @Transactional
    public AdminResponse updateProfile(Long idAdmin, String newUsername) {
        AdminUser admin = find(idAdmin);
        String username = newUsername.trim();
        repository.findByUsernameIgnoreCase(username)
                .filter(other -> !other.getIdAdmin().equals(idAdmin))
                .ifPresent(other -> {
                    throw new AdminException(AdminError.USERNAME_TAKEN);
                });
        admin.setUsername(username);
        return toResponse(admin);
    }

    @Transactional(noRollbackFor = AdminException.class)
    public void changePassword(Long idAdmin, String currentPassword, String newPassword) {
        AdminUser admin = find(idAdmin);
        if (!passwordEncoder.matches(currentPassword, admin.getPasswordHash())) {
            int attempts = admin.getFailedAttempts() + 1;
            admin.setFailedAttempts(attempts);
            if (attempts >= MAX_FAILED_ATTEMPTS) {
                admin.setLockedUntil(Instant.now().plus(LOCK_DURATION));
                log.warn("Admin '{}' bloqueado ao alterar password", admin.getUsername());
            }
            throw new AdminException(AdminError.WRONG_CURRENT_PASSWORD);
        }
        requireStrongPassword(newPassword, false);
        admin.setPasswordHash(passwordEncoder.encode(newPassword));
        admin.setFailedAttempts(0);
        admin.setLockedUntil(null);
    }

        public record AuditEntry(Long id, Long adminId, String username, String action,
                             Long licenseId, String ip, Instant createdAt) {
    }

    // Acao feita por um admin autenticado (identidade vem do JWT)
    public void audit(Jwt jwt, String action, Long licenseId, String ip) {
        Object claim = jwt.getClaim("adminId");
        Long adminId = claim instanceof Number n ? n.longValue() : null;
        record(adminId, jwt.getSubject(), action, licenseId, ip);
    }

    // Acao sem token (login): so ha o username que a pessoa escreveu
    public void auditAnonymous(String username, String action, String ip) {
        record(null, username, action, null, ip);
    }

    // A acao ja foi concluida quando chegamos aqui: uma falha na auditoria nao a desfaz
    private void record(Long adminId, String username, String action, Long licenseId, String ip) {
        try {
            AdminAuditLog entry = new AdminAuditLog();
            entry.setAdminId(adminId);
            entry.setUsername(truncate(username, 50));
            entry.setAction(action);
            entry.setLicenseId(licenseId);
            entry.setIp(truncate(ip, 45));
            auditRepository.save(entry);
        } catch (RuntimeException e) {
            log.error("Falha ao registar auditoria: action={} licenseId={}", action, licenseId, e);
        }
    }

    @Transactional(readOnly = true)
    public PagedModel<AuditEntry> listAudit(Long licenseId, Pageable pageable) {
        Page<AdminAuditLog> page = licenseId == null
                ? auditRepository.findAllByOrderByCreatedAtDesc(pageable)
                : auditRepository.findByLicenseIdOrderByCreatedAtDesc(licenseId, pageable);
        return new PagedModel<>(page.map(a -> new AuditEntry(a.getIdAudit(), a.getAdminId(),
                a.getUsername(), a.getAction(), a.getLicenseId(), a.getIp(), a.getCreatedAt())));
    }

    private static String truncate(String s, int max) {
        return s == null || s.length() <= max ? s : s.substring(0, max);
    }

    // ---------- helpers ----------

    private AdminUser find(Long idAdmin) {
        return repository.findById(idAdmin)
                .orElseThrow(() -> new AdminException(AdminError.ADMIN_NOT_FOUND));
    }

    private AdminResponse toResponse(AdminUser admin) {
        return new AdminResponse(admin.getIdAdmin(), admin.getUsername(),
                admin.getLastLoginAt(), admin.getCreatedAt());
    }

    private void requireStrongPassword(String password, boolean bootstrap) {
        if (password.length() < MIN_PASSWORD_LENGTH) {
            if (bootstrap) {
                throw new IllegalStateException(
                        "admin.bootstrap.password deve ter pelo menos " + MIN_PASSWORD_LENGTH + " caracteres");
            }
            throw new AdminException(AdminError.WEAK_PASSWORD);
        }
    }

    private String issueToken(AdminUser admin, Instant now) {
        JwtClaimsSet claims = JwtClaimsSet.builder()
                .issuer(ISSUER)
                .subject(admin.getUsername())
                .issuedAt(now)
                .expiresAt(now.plus(tokenTtl))
                .claim("adminId", admin.getIdAdmin())
                .build();
        JwsHeader header = JwsHeader.with(MacAlgorithm.HS256).build();
        return jwtEncoder.encode(JwtEncoderParameters.from(header, claims)).getTokenValue();
    }
}