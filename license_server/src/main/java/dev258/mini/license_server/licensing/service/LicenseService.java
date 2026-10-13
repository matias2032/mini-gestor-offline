package dev258.mini.license_server.licensing.service;

import dev258.mini.license_server.licensing.entity.License;
import dev258.mini.license_server.licensing.entity.LicenseStatus;
import dev258.mini.license_server.licensing.exception.LicenseError;
import dev258.mini.license_server.licensing.exception.LicenseException;
import dev258.mini.license_server.licensing.repository.LicenseRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.*;
import java.security.spec.PKCS8EncodedKeySpec;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;
import java.util.List;
import java.util.Locale;

@Slf4j
@Service
public class LicenseService {

    private static final String ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    private static final int CODE_LENGTH = 16;
    private static final SecureRandom RANDOM = new SecureRandom();

    private static final int PAYLOAD_VERSION = 1;
    private static final Base64.Encoder B64URL = Base64.getUrlEncoder().withoutPadding();

    private final LicenseRepository repository;
    private final PrivateKey privateKey;

    public LicenseService(LicenseRepository repository, @Value("${license.private-key}") String privateKeyBase64) {
        this.repository = repository;
        this.privateKey = loadKey(privateKeyBase64);
        if (this.privateKey == null) {
            log.warn("license.private-key vazia: o servidor arranca, mas nao consegue assinar licencas");
        }
    }

    public record GeneratedLicense(Long id, String code, String channel, String buyerLabel) {
    }

    public record SignedLicense(String payload, String signature) {
    }

    @Transactional
    public SignedLicense activate(String code, String deviceId) {
        String normalized = normalize(code);
        if (normalized.length() != CODE_LENGTH) {
            throw new LicenseException(LicenseError.INVALID_CODE);
        }

        License license = repository.findByCodeHashForUpdate(sha256(normalized))
                .orElseThrow(() -> new LicenseException(LicenseError.INVALID_CODE));

        switch (license.getStatus()) {
            case REVOKED -> throw new LicenseException(LicenseError.REVOKED);
            case ACTIVE -> {
                if (!deviceId.equals(license.getDeviceId())) {
                    throw new LicenseException(LicenseError.ALREADY_USED);
                }
            }
            case UNUSED -> {
                license.setStatus(LicenseStatus.ACTIVE);
                license.setDeviceId(deviceId);
                license.setActivatedAt(Instant.now());
                license.setActivationCount(license.getActivationCount() + 1);
            }
        }

        // issuedAt = activatedAt: reativar no mesmo aparelho devolve exatamente a mesma resposta
        return sign(license.getIdLicense(), deviceId, license.getActivatedAt());
    }

    @Transactional
    public GeneratedLicense generate(String channel, String buyerLabel) {
        String raw = randomCode();

        License license = new License();
        license.setCodeHash(sha256(raw));
        license.setCodeHint(raw.substring(CODE_LENGTH - 4));
        license.setChannel(channel);
        license.setBuyerLabel(buyerLabel);
        repository.save(license);

        return new GeneratedLicense(license.getIdLicense(), format(raw), channel, buyerLabel);
    }

    @Transactional
    public void reset(Long id) {
        License license = find(id);
        if (license.getStatus() == LicenseStatus.REVOKED) {
            throw new LicenseException(LicenseError.REVOKED);
        }
        license.setStatus(LicenseStatus.UNUSED);
        license.setDeviceId(null);
        license.setActivatedAt(null);
    }

    @Transactional
    public void revoke(Long id) {
        find(id).setStatus(LicenseStatus.REVOKED);
    }

    @Transactional(readOnly = true)
    public List<License> findByBuyer(String buyer) {
        if (buyer == null || buyer.isBlank()) {
            return repository.findAll(Sort.by(Sort.Direction.DESC, "createdAt"));
        }
        return repository.findByBuyerLabelContainingIgnoreCase(buyer.trim());
    }

    public SignedLicense sign(long licenseId, String deviceId, Instant issuedAt) {
        if (privateKey == null) {
            throw new IllegalStateException("LICENSE_PRIVATE_KEY nao definida: impossivel assinar");
        }
        byte[] payload = buildPayload(licenseId, deviceId, issuedAt).getBytes(StandardCharsets.UTF_8);
        try {
            Signature signature = Signature.getInstance("Ed25519");
            signature.initSign(privateKey);
            signature.update(payload);
            return new SignedLicense(
                    B64URL.encodeToString(payload),
                    B64URL.encodeToString(signature.sign()));
        } catch (GeneralSecurityException e) {
            throw new IllegalStateException("Falha ao assinar a licenca", e);
        }
    }

    private License find(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> new LicenseException(LicenseError.INVALID_CODE));
    }

    private static String randomCode() {
        char[] chars = new char[CODE_LENGTH];
        for (int i = 0; i < CODE_LENGTH; i++) {
            chars[i] = ALPHABET.charAt(RANDOM.nextInt(ALPHABET.length()));
        }
        return new String(chars);
    }

    private static String format(String raw) {
        return raw.substring(0, 4) + "-" + raw.substring(4, 8) + "-"
                + raw.substring(8, 12) + "-" + raw.substring(12, 16);
    }

    // Aceita minusculas, espacos e hifens: o cliente copia o codigo do WhatsApp como quiser
    private static String normalize(String code) {
        if (code == null) {
            return "";
        }
        return code.replaceAll("[\\s-]", "").toUpperCase(Locale.ROOT);
    }

    private static String sha256(String value) {
        try {
            byte[] hash = MessageDigest.getInstance("SHA-256")
                    .digest(value.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }

    // JSON montado a mao: ordem dos campos fixa e sem depender do Jackson 3
    private static String buildPayload(long licenseId, String deviceId, Instant issuedAt) {
        return "{\"v\":" + PAYLOAD_VERSION
                + ",\"licenseId\":" + licenseId
                + ",\"deviceId\":\"" + escape(deviceId) + "\""
                + ",\"issuedAt\":" + issuedAt.getEpochSecond() + "}";
    }

    private static String escape(String s) {
        StringBuilder sb = new StringBuilder(s.length() + 8);
        for (char c : s.toCharArray()) {
            switch (c) {
                case '"' -> sb.append("\\\"");
                case '\\' -> sb.append("\\\\");
                default -> {
                    if (c < 0x20) {
                        sb.append(String.format("\\u%04x", (int) c));
                    } else {
                        sb.append(c);
                    }
                }
            }
        }
        return sb.toString();
    }

    private static PrivateKey loadKey(String base64) {
        if (base64 == null || base64.isBlank()) {
            return null;
        }
        try {
            byte[] der = Base64.getDecoder().decode(base64.trim());
            return KeyFactory.getInstance("Ed25519").generatePrivate(new PKCS8EncodedKeySpec(der));
        } catch (GeneralSecurityException | IllegalArgumentException e) {
            throw new IllegalStateException(
                    "LICENSE_PRIVATE_KEY invalida: esperado PKCS8 DER em base64", e);
        }
    }
}