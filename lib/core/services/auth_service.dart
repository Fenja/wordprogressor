import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Unified authentication service supporting:
///   - Email / Password
///   - Google Sign-In  (Android, iOS, Web)
///   - Apple Sign-In   (iOS 13+, macOS 10.15+, Web)
class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              // Request profile + email scopes — enough for WordProgressor.
              scopes: ['email', 'profile'],
            );

  // ── State ──────────────────────────────────────────────────────────────────

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  // ── Email / Password ───────────────────────────────────────────────────────

  Future<UserCredential> signInWithEmail(
      String email, String password) {
    return _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
  }

  Future<UserCredential> registerWithEmail(
      String email, String password) {
    return _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      // Web: use Firebase popup flow — no native Google Sign-In SDK needed.
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile');
      return _auth.signInWithPopup(provider);
    }

    // Native (Android / iOS):
    // 1. Trigger the Google authentication flow.
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw AuthException('google-sign-in-cancelled',
          'Google Sign-In wurde abgebrochen.');
    }

    // 2. Obtain auth details.
    final googleAuth = await googleUser.authentication;

    // 3. Create Firebase credential.
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // 4. Sign in to Firebase.
    return _auth.signInWithCredential(credential);
  }

  // ── Apple Sign-In ──────────────────────────────────────────────────────────

  /// Apple Sign-In requires a SHA-256 nonce to prevent replay attacks.
  /// The raw nonce is sent to Apple; the hashed nonce is sent to Firebase.
  Future<UserCredential> signInWithApple() async {
    if (kIsWeb) {
      // Web: use Firebase redirect/popup flow.
      final provider = OAuthProvider('apple.com')
        ..addScope('email')
        ..addScope('name');
      return _auth.signInWithPopup(provider);
    }

    // Native (iOS / macOS):
    final rawNonce = _generateNonce();
    final hashedNonce = _sha256(rawNonce);

    // 1. Request Apple credential.
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    // 2. Create OAuth credential for Firebase.
    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    // 3. Sign in to Firebase.
    final userCredential = await _auth.signInWithCredential(oauthCredential);

    // 4. Apple only sends the display name on the very first sign-in.
    //    Persist it to the Firebase user profile before it is lost.
    final fullName = [
      appleCredential.givenName,
      appleCredential.familyName,
    ].where((s) => s != null && s.isNotEmpty).join(' ');

    if (fullName.isNotEmpty &&
        (userCredential.user?.displayName?.isEmpty ?? true)) {
      await userCredential.user?.updateDisplayName(fullName);
    }

    return userCredential;
  }

  // ── Apple availability ─────────────────────────────────────────────────────

  /// Returns true when Apple Sign-In is available on this device.
  /// Always true on iOS 13+, macOS 10.15+, and web.
  /// On Android: false (Apple does not support Android natively).
  static Future<bool> isAppleSignInAvailable() async {
    if (kIsWeb) return true;
    return SignInWithApple.isAvailable();
  }

  // ── Sign-out ───────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    // Sign out of both Google and Firebase so the account-picker
    // shows next time (not the previously selected account silently).
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut().catchError((_) {}),
    ]);
  }

  // ── Nonce helpers (Apple) ──────────────────────────────────────────────────

  /// Generates a cryptographically random nonce string.
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the SHA-256 hash of [input] as a lowercase hex string.
  String _sha256(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

// ── Custom exception ───────────────────────────────────────────────────────────

class AuthException implements Exception {
  final String code;
  final String message;
  const AuthException(this.code, this.message);

  @override
  String toString() => message;
}

// ── Providers ─────────────────────────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Convenience: true when a user is signed in.
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).valueOrNull != null;
});

/// The current Firebase user (null when signed out).
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

/// Whether Apple Sign-In is available on this platform/device.
final appleSignInAvailableProvider = FutureProvider<bool>((ref) {
  return AuthService.isAppleSignInAvailable();
});