import 'package:firebase_auth/firebase_auth.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:flutter/foundation.dart';

/// Thin wrapper around [FirebaseAuth] phone authentication.
///
/// Keeps Firebase types out of the UI layer and makes the provider testable.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Starts phone-number verification. Firebase decides which callback fires:
  /// [verificationCompleted] on Android auto-retrieval, [codeSent] otherwise.
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) codeSent,
    required void Function(FirebaseAuthException e) verificationFailed,
    required void Function(PhoneAuthCredential credential) verificationCompleted,
    int? forceResendingToken,
  }) async {
    if (kIsWeb) {
      try {
        // FirebaseAuthPlatform.instance is FirebaseAuthWeb on web.
        // Passing no container triggers invisible reCAPTCHA internally.
        final recaptchaVerifier = RecaptchaVerifier(
          auth: FirebaseAuthPlatform.instance,
        );
        final confirmationResult = await _auth.signInWithPhoneNumber(
          phoneNumber,
          recaptchaVerifier,
        );
        codeSent(confirmationResult.verificationId, null);
      } on FirebaseAuthException catch (e) {
        verificationFailed(e);
      }
      return;
    }

    return _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: forceResendingToken,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  /// Completes sign-in from a manually entered SMS code.
  Future<UserCredential> signInWithSmsCode({
    required String verificationId,
    required String smsCode,
  }) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _auth.signInWithCredential(credential);
  }

  /// Completes sign-in from an auto-retrieved credential.
  Future<UserCredential> signInWithCredential(PhoneAuthCredential credential) {
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() => _auth.signOut();
}