import 'dart:convert';

import 'package:android_id/android_id.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mini/core/config/api_config.dart';

enum LicenseErrorCode {
  invalidCode,
  alreadyUsed,
  revoked,
  rateLimited,
  network,
  deviceUnavailable,
  invalidResponse,
}

class LicenseException implements Exception {
  const LicenseException(this.code);
  final LicenseErrorCode code;

  @override
  String toString() => 'LicenseException: $code';
}

/* One-time online activation, offline validation afterwards.

The server signs {licenseId, deviceId} with an Ed25519 private key; the app only holds the public key, so it can verify a license
but never forge one. The signed license lives in secure storage, deliberately outside SQLite: BackupService exports every
table, and a license inside the database would travel with a backup to another device. */
class LicenseService {


  // Raw 32-byte Ed25519 public key, base64 (see the openssl command).
  static const String _publicKeyBase64 = 'H9/z3ApRN3rrDXJ7j1m/1vNE7fRq9IQJ8+kR3QtrOwU=';

  static const String _storageKey = 'license_v1';

  // Debug builds skip the check unless this is switched on to test the flow.
  static const bool _enforceInDebug = false;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /* True when a stored license has a valid signature and belongs to this device. Any failure (missing, tampered, other device,
  storage unreadable) counts as "not licensed" and sends the user to activation, which is idempotent for the same device. */
  Future<bool> hasValidLicense() async {
    if (kDebugMode && !_enforceInDebug) return true;

    try {
      final stored = await _storage.read(key: _storageKey);
      if (stored == null) return false;

      final data = jsonDecode(stored) as Map<String, dynamic>;
      return await _isAuthentic(
        payload: data['payload'] as String,
        signature: data['signature'] as String,
        deviceId: await _deviceId(),
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> activate(String code) async {
    final deviceId = await _deviceId();

    final http.Response response;
    try {
      response = await http
          .post(
            ApiConfig.uri(ApiConfig.activateLicense),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'code': code.trim(), 'deviceId': deviceId}),
          )
          .timeout(ApiConfig.timeout);
    } on Exception catch (_) {
      throw const LicenseException(LicenseErrorCode.network);
    }

    switch (response.statusCode) {
      case 200:
        break;
      case 404:
        throw const LicenseException(LicenseErrorCode.invalidCode);
      case 409:
        throw const LicenseException(LicenseErrorCode.alreadyUsed);
      case 403:
        throw const LicenseException(LicenseErrorCode.revoked);
      case 429:
        throw const LicenseException(LicenseErrorCode.rateLimited);
      default:
        throw const LicenseException(LicenseErrorCode.invalidResponse);
    }

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const LicenseException(LicenseErrorCode.invalidResponse);
    }

    final payload = data['payload'] as String?;
    final signature = data['signature'] as String?;
    if (payload == null ||
        signature == null ||
        !await _isAuthentic(
          payload: payload,
          signature: signature,
          deviceId: deviceId,
        )) {
      throw const LicenseException(LicenseErrorCode.invalidResponse);
    }

    await _storage.write(
      key: _storageKey,
      value: jsonEncode({'payload': payload, 'signature': signature}),
    );
  }

  Future<bool> _isAuthentic({
    required String payload,
    required String signature,
    required String deviceId,
  }) async {
    final payloadBytes = _decodeBase64Url(payload);
    final publicKey = SimplePublicKey(
      base64Decode(_publicKeyBase64),
      type: KeyPairType.ed25519,
    );

    final isValid = await Ed25519().verify(
      payloadBytes,
      signature: Signature(_decodeBase64Url(signature), publicKey: publicKey),
    );
    if (!isValid) return false;

    final claims = jsonDecode(utf8.decode(payloadBytes)) as Map<String, dynamic>;
    return claims['deviceId'] == deviceId;
  }

  Future<String> _deviceId() async {
    final id = await const AndroidId().getId();
    if (id == null || id.isEmpty) {
      throw const LicenseException(LicenseErrorCode.deviceUnavailable);
    }
    return id;
  }

  List<int> _decodeBase64Url(String value) =>
      base64Url.decode(base64Url.normalize(value));
}