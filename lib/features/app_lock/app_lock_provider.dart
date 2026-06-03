import 'package:flutter/foundation.dart';

import 'app_lock_service.dart';

class AppLockProvider extends ChangeNotifier {
  AppLockProvider(this._service) {
    _init();
  }

  final AppLockService _service;

  bool _initialized = false;
  bool _locked = true; // always locked at cold start
  bool _hasPin = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;

  bool get initialized => _initialized;
  bool get locked => _locked;
  bool get hasPin => _hasPin;
  bool get biometricEnabled => _biometricEnabled;
  bool get biometricAvailable => _biometricAvailable;

  Future<void> _init() async {
    _hasPin = await _service.hasPin();
    _biometricEnabled = await _service.getBiometricEnabled();
    _biometricAvailable = await _service.isBiometricAvailable();
    _initialized = true;
    notifyListeners();
  }

  void unlock() {
    _locked = false;
    notifyListeners();
  }

  Future<bool> unlockWithPin(String pin) async {
    if (!await _service.verifyPin(pin)) return false;
    _locked = false;
    notifyListeners();
    return true;
  }

  Future<bool> unlockWithBiometric() async {
    if (!await _service.authenticateBiometric()) return false;
    _locked = false;
    notifyListeners();
    return true;
  }

  /// Saves the PIN hash, marks the PIN as set, and unlocks the session.
  /// Works for first-time setup, forgot-PIN reset, and settings change.
  Future<void> setPin(String pin) async {
    await _service.setPin(pin);
    _hasPin = true;
    _locked = false;
    notifyListeners();
  }

  /// Verifies [pin] against the stored hash without changing any lock state.
  /// Used by the "Change PIN" flow to confirm the user knows the current PIN.
  Future<bool> verifyCurrentPin(String pin) => _service.verifyPin(pin);

  Future<void> setBiometricEnabled(bool value) async {
    await _service.setBiometricEnabled(value);
    _biometricEnabled = value;
    notifyListeners();
  }
}
