import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/services.dart';

/// Phase of the phone-number verification flow, used to drive UI feedback.
enum PhoneAuthStatus { idle, sending, codeSent, verifying, error }

/// Single source of truth for authentication + onboarding state.
///
/// Listens to Firebase auth changes, loads the matching profile document, and
/// exposes the phone-verification flow plus the onboarding draft (name → role).
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService, UserService? userService})
      : _authService = authService ?? AuthService(),
        _userService = userService ?? UserService() {
    _sub = _authService.authStateChanges().listen(_onAuthStateChanged);
  }

  final AuthService _authService;
  final UserService _userService;
  late final StreamSubscription<User?> _sub;

  // --- Session state -------------------------------------------------------

  bool _initialized = false;

  /// True once the first auth state (and profile, if signed in) has resolved.
  /// The app shows a splash until this flips, so the router never redirects
  /// against a half-known state.
  bool get initialized => _initialized;

  User? _firebaseUser;
  UserModel? _userModel;

  UserModel? get userModel => _userModel;
  bool get isAuthenticated => _firebaseUser != null;
  bool get hasProfile => _userModel != null;

  // --- Phone verification flow --------------------------------------------

  PhoneAuthStatus _status = PhoneAuthStatus.idle;
  String? _errorMessage;
  String? _verificationId;
  int? _resendToken;
  String _pendingPhone = '';

  PhoneAuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String get pendingPhone => _pendingPhone;
  bool get isBusy =>
      _status == PhoneAuthStatus.sending || _status == PhoneAuthStatus.verifying;

  // --- Onboarding draft ----------------------------------------------------

  String? _draftFirstName;
  String? _draftLastName;

  String? get draftFirstName => _draftFirstName;
  String? get draftLastName => _draftLastName;

  // -------------------------------------------------------------------------

  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    if (user != null) {
      try {
        _userModel = await _userService.getUser(user.uid);
      } catch (_) {
        _userModel = null;
      }
    } else {
      _userModel = null;
    }
    _initialized = true;
    notifyListeners();
  }

  /// Begins (or resends) SMS verification for [phoneNumber] (E.164 format).
  Future<void> sendCode(String phoneNumber, {bool resend = false}) async {
    _pendingPhone = phoneNumber;
    _status = PhoneAuthStatus.sending;
    _errorMessage = null;
    notifyListeners();

    await _authService.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: resend ? _resendToken : null,
      verificationCompleted: (credential) async {
        // Android auto-retrieval: complete sign-in without manual entry.
        try {
          await _authService.signInWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          _failWith(e.message ?? 'Automatic verification failed');
        }
      },
      verificationFailed: (e) {
        _failWith(e.message ?? 'Verification failed. Please try again.');
      },
      codeSent: (verificationId, resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        _status = PhoneAuthStatus.codeSent;
        notifyListeners();
      },
    );
  }

  /// Verifies the manually entered 6-digit [smsCode]. Returns true on success;
  /// the auth-state listener then loads the profile and triggers redirect.
  Future<bool> verifyOtp(String smsCode) async {
    final verificationId = _verificationId;
    if (verificationId == null) {
      _failWith('Verification expired. Please request a new code.');
      return false;
    }
    _status = PhoneAuthStatus.verifying;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signInWithSmsCode(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      _status = PhoneAuthStatus.idle;
      return true;
    } on FirebaseAuthException catch (e) {
      _failWith(e.message ?? 'Invalid code. Please try again.');
      return false;
    }
  }

  /// Stores the name captured on the profile screen for the onboarding draft.
  void setName({required String firstName, String? lastName}) {
    _draftFirstName = firstName.trim();
    final last = lastName?.trim();
    _draftLastName = (last == null || last.isEmpty) ? null : last;
    notifyListeners();
  }

  /// Final onboarding step: writes the profile document with the chosen [role].
  Future<void> completeOnboarding(UserRole role) async {
    final user = _firebaseUser;
    if (user == null) return;

    final fullName = [_draftFirstName, _draftLastName]
        .where((part) => part != null && part.isNotEmpty)
        .join(' ')
        .trim();

    _userModel = await _userService.createUser(
      uid: user.uid,
      phone: user.phoneNumber ?? _pendingPhone,
      role: role,
      name: fullName.isEmpty ? null : fullName,
    );
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _resetFlow();
  }

  void clearError() {
    if (_status == PhoneAuthStatus.error) _status = PhoneAuthStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  void _failWith(String message) {
    _status = PhoneAuthStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  void _resetFlow() {
    _status = PhoneAuthStatus.idle;
    _errorMessage = null;
    _verificationId = null;
    _resendToken = null;
    _pendingPhone = '';
    _draftFirstName = null;
    _draftLastName = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
