import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class AppLockService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    webOptions: WebOptions(dbName: 'we_are_ready', publicKey: 'alp'),
  );

  String _keyPinHash(String uid) => 'alp_pin_hash_$uid';
  String _keyBiometric(String uid) => 'alp_biometric_$uid';

  final _auth = LocalAuthentication();

  String _hash(String pin) => sha256.convert(utf8.encode(pin)).toString();

  Future<void> setPin(String pin, String uid) =>
      _storage.write(key: _keyPinHash(uid), value: _hash(pin));

  Future<bool> verifyPin(String pin, String uid) async {
    final stored = await _storage.read(key: _keyPinHash(uid));
    return stored != null && stored == _hash(pin);
  }

  Future<bool> hasPin(String uid) async =>
      (await _storage.read(key: _keyPinHash(uid))) != null;

  Future<void> deletePin(String uid) =>
      _storage.delete(key: _keyPinHash(uid));

  Future<void> setBiometricEnabled(bool v, String uid) =>
      _storage.write(key: _keyBiometric(uid), value: v.toString());

  Future<bool> getBiometricEnabled(String uid) async =>
      (await _storage.read(key: _keyBiometric(uid))) == 'true';

  Future<bool> isBiometricAvailable() async {
    if (kIsWeb) return false;
    try {
      return await _auth.canCheckBiometrics && await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateBiometric() async {
    if (kIsWeb) return false;
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock WeAreReady',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
