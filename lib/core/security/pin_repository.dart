import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/theme_controller.dart';

final pinRepositoryProvider = Provider<PinRepository>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return PinRepository(prefs);
});

class PinRepository {
  PinRepository(this._prefs);

  static const _pinHashKey = 'auth_pin_hash';
  static const _pinSaltKey = 'auth_pin_salt';
  static const _bioEnabledKey = 'auth_bio_enabled';

  final SharedPreferences _prefs;

  bool get hasPin => _prefs.containsKey(_pinHashKey);

  bool get isBiometricEnabled => _prefs.getBool(_bioEnabledKey) ?? false;

  Future<void> setBiometricEnabled(bool enabled) async {
    await _prefs.setBool(_bioEnabledKey, enabled);
  }

  Future<void> savePin(String pin) async {
    final salt = _generateSalt();
    final hash = _hash(pin, salt);
    await _prefs.setString(_pinHashKey, hash);
    await _prefs.setString(_pinSaltKey, salt);
  }

  bool verifyPin(String pin) {
    final salt = _prefs.getString(_pinSaltKey);
    final storedHash = _prefs.getString(_pinHashKey);
    if (salt == null || storedHash == null) return false;
    return _hash(pin, salt) == storedHash;
  }

  Future<void> clear() async {
    await _prefs.remove(_pinHashKey);
    await _prefs.remove(_pinSaltKey);
    await _prefs.remove(_bioEnabledKey);
  }

  String _hash(String value, String salt) {
    final bytes = utf8.encode('$value:$salt');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _generateSalt() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return base64Url.encode(bytes);
  }
}
