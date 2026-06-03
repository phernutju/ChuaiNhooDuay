import 'package:flutter/foundation.dart';

import 'app_lock_service.dart';

class AppLockProvider extends ChangeNotifier {
  AppLockProvider(this._service);

  final AppLockService _service;
  String? _uid;

  bool _initialized = false;
  bool _locked = true;
  bool _hasPin = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;

  bool get initialized => _initialized;
  bool get locked => _locked;
  bool get hasPin => _hasPin;
  bool get biometricEnabled => _biometricEnabled;
  bool get biometricAvailable => _biometricAvailable;

  Future<void> initForUser(String uid) async {
    print('initForUser called with uid: $uid');
    if (_uid == uid && _initialized) return;
    _uid = uid;
    _initialized = false;
    _locked = true;
    _hasPin = await _service.hasPin(uid);
    _biometricEnabled = await _service.getBiometricEnabled(uid);
    _biometricAvailable = await _service.isBiometricAvailable();
    _initialized = true;
    notifyListeners();
  }

  void unlock() {
    _locked = false;
    notifyListeners();
  }

  Future<bool> unlockWithPin(String pin) async {
    if (_uid == null) return false;
    if (!await _service.verifyPin(pin, _uid!)) return false;
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

  Future<void> setPin(String pin) async {
    if (_uid == null) return;
    await _service.setPin(pin, _uid!);
    _hasPin = true;
    _locked = false;
    notifyListeners();
  }

  Future<bool> verifyCurrentPin(String pin) {
    if (_uid == null) return Future.value(false);
    return _service.verifyPin(pin, _uid!);
  }

  Future<void> setBiometricEnabled(bool value) async {
    if (_uid == null) return;
    await _service.setBiometricEnabled(value, _uid!);
    _biometricEnabled = value;
    notifyListeners();
  }
}
