/// Supabase email/password authentication for development sign-in.
///
/// This authenticates the user and supplies a short-lived access token for
/// `Authorization: Bearer` requests to the NEMRAS backend, which verifies it.
/// Signing in does not bind the account to a CNIC and authorises no access to
/// a patient record.
///
/// Access tokens, refresh tokens and passwords are never logged, printed or
/// shown. Error messages are fixed strings and never echo server text.
library;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// Thrown when an operation needs a signed-in session and there is none.
class SignInRequired extends StateError {
  SignInRequired() : super('Sign in before calling the backend');
}

enum AuthFailureKind {
  notConfigured,
  invalidCredentials,
  emailNotConfirmed,
  rateLimited,
  network,
  unknown,
}

/// A sign-in or session failure with a message that is safe to display.
class AuthFailure implements Exception {
  const AuthFailure(this.kind, this.message);

  final AuthFailureKind kind;
  final String message;

  @override
  String toString() => message;
}

/// Starts Supabase when this build is configured for it.
///
/// Returns the configuration check so the UI can explain a missing or
/// invalid configuration instead of failing silently. Never throws.
Future<SupabaseConfigCheck> initializeSupabase() async {
  final check = SupabaseConfig.current;
  final config = check.config;
  if (config == null) return _startupCheck = check;
  try {
    await Supabase.initialize(
      url: config.url,
      publishableKey: config.publishableKey,
      debug: false,
    );
    _supabaseReady = true;
  } on Object {
    return _startupCheck = SupabaseConfigCheck.initializationFailed;
  }
  return _startupCheck = check;
}

bool _supabaseReady = false;
SupabaseConfigCheck _startupCheck = SupabaseConfig.current;

/// True once [initializeSupabase] has started the client.
bool get isSupabaseReady => _supabaseReady;

/// The outcome of [initializeSupabase], for explaining why sign-in is off.
SupabaseConfigCheck get supabaseStartupCheck => _startupCheck;

class NemrasAuthService {
  NemrasAuthService(this._auth);

  /// The app-wide service. Throws [AuthFailure] when Supabase was not
  /// configured at build time.
  factory NemrasAuthService.instance() {
    if (!_supabaseReady) {
      throw const AuthFailure(
        AuthFailureKind.notConfigured,
        'Supabase sign-in is not configured in this build.',
      );
    }
    return NemrasAuthService(Supabase.instance.client.auth);
  }

  final GoTrueClient _auth;

  bool get isSignedIn => _auth.currentSession != null;

  /// The signed-in user's own e-mail, for display to that user only.
  String? get signedInEmail => _auth.currentUser?.email;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithPassword(email: email.trim(), password: password);
    } on AuthException catch (error) {
      throw mapAuthException(error);
    } on Exception {
      throw _networkFailure;
    }
  }

  /// Ends the session on this device. The local session is cleared even if
  /// the server cannot be reached.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on Object {
      if (_auth.currentSession != null) {
        throw const AuthFailure(
          AuthFailureKind.network,
          'Could not sign out. Check your connection and try again.',
        );
      }
    }
  }

  /// A current access token for the backend, refreshing an expired session.
  ///
  /// Throws [SignInRequired] when there is no usable session.
  Future<String> accessToken() async {
    var session = _auth.currentSession;
    if (session == null) throw SignInRequired();
    if (session.isExpired) {
      try {
        session = (await _auth.refreshSession()).session;
      } on AuthRetryableFetchException {
        throw _networkFailure;
      } on AuthException {
        throw SignInRequired();
      }
    }
    if (session == null) throw SignInRequired();
    return session.accessToken;
  }

  static const AuthFailure _networkFailure = AuthFailure(
    AuthFailureKind.network,
    'Cannot reach the sign-in service. Check your connection and try again.',
  );
}

/// Maps a Supabase auth error to a fixed, user-safe message.
@visibleForTesting
AuthFailure mapAuthException(AuthException error) {
  if (error is AuthRetryableFetchException) {
    return NemrasAuthService._networkFailure;
  }
  switch (error.code) {
    case 'invalid_credentials':
      return const AuthFailure(
        AuthFailureKind.invalidCredentials,
        'Email or password is incorrect.',
      );
    case 'email_not_confirmed':
      return const AuthFailure(
        AuthFailureKind.emailNotConfirmed,
        'This account has not confirmed its email address yet.',
      );
    case 'over_request_rate_limit':
    case 'over_email_send_rate_limit':
      return const AuthFailure(
        AuthFailureKind.rateLimited,
        'Too many sign-in attempts. Wait a moment and try again.',
      );
  }
  if (error.statusCode == '400' &&
      error.message.toLowerCase().contains('invalid login credentials')) {
    return const AuthFailure(
      AuthFailureKind.invalidCredentials,
      'Email or password is incorrect.',
    );
  }
  return const AuthFailure(
    AuthFailureKind.unknown,
    'Sign-in failed. Try again later.',
  );
}
