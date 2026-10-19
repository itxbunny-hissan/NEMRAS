/// ============================================================
/// SUPABASE CONFIGURATION (build-time, non-secret values only)
/// ============================================================
/// Supplied with --dart-define, never edited into source:
///
///   flutter run \
///     --dart-define=SUPABASE_URL=https://<dev-project-ref>.supabase.co \
///     --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
///
/// Only the project URL and the PUBLISHABLE key belong in a client. The
/// secret key (sb_secret_...), the service-role key, the JWT secret and the
/// database password must never be compiled into this app. [validate]
/// refuses the recognisable ones rather than silently using them.
///
/// Signing in authenticates the user only. It does not bind the account to a
/// CNIC and does not authorise access to any patient record.
/// ============================================================
library;

import 'dart:convert';

const String kSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String kSupabasePublishableKey =
    String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

/// Validated Supabase settings.
class SupabaseConfig {
  const SupabaseConfig._(this.url, this.publishableKey);

  final String url;
  final String publishableKey;

  /// The build's own configuration.
  static final SupabaseConfigCheck current =
      validate(url: kSupabaseUrl, publishableKey: kSupabasePublishableKey);

  /// Checks the two values without ever echoing the key back.
  static SupabaseConfigCheck validate({
    required String url,
    required String publishableKey,
  }) {
    final trimmedUrl = url.trim();
    final key = publishableKey.trim();

    if (trimmedUrl.isEmpty && key.isEmpty) {
      return const SupabaseConfigCheck._problem(
        'Supabase sign-in is not configured in this build. Rebuild with '
        '--dart-define=SUPABASE_URL=... and '
        '--dart-define=SUPABASE_PUBLISHABLE_KEY=...',
      );
    }

    final normalizedUrl = _normalizeUrl(trimmedUrl);
    if (normalizedUrl == null) {
      return const SupabaseConfigCheck._problem(
        'SUPABASE_URL must be the https project URL, for example '
        'https://<project-ref>.supabase.co, with no path.',
      );
    }

    if (key.isEmpty) {
      return const SupabaseConfigCheck._problem(
        'SUPABASE_PUBLISHABLE_KEY is missing from this build.',
      );
    }
    if (key.startsWith('sb_secret_') || _jwtRole(key) == 'service_role') {
      return const SupabaseConfigCheck._problem(
        'A Supabase SECRET key was supplied to the app. Only the publishable '
        'key may be used in a client. Rotate that secret key in the '
        'Supabase dashboard and rebuild with the publishable key.',
      );
    }
    final isPublishable = key.startsWith('sb_publishable_');
    final isLegacyAnon = _jwtRole(key) == 'anon';
    if (!isPublishable && !isLegacyAnon) {
      return const SupabaseConfigCheck._problem(
        'SUPABASE_PUBLISHABLE_KEY is not a Supabase publishable key.',
      );
    }

    return SupabaseConfigCheck._ok(SupabaseConfig._(normalizedUrl, key));
  }

  static const Set<String> _localHosts = {'localhost', '127.0.0.1', '10.0.2.2'};

  static String? _normalizeUrl(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.host.isEmpty) return null;
    final secure = uri.scheme == 'https';
    final local = uri.scheme == 'http' && _localHosts.contains(uri.host);
    if (!secure && !local) return null;
    if (uri.path.isNotEmpty && uri.path != '/') return null;
    if (uri.hasQuery || uri.hasFragment || uri.userInfo.isNotEmpty) return null;
    return uri.hasPort
        ? '${uri.scheme}://${uri.host}:${uri.port}'
        : '${uri.scheme}://${uri.host}';
  }

  /// Reads the `role` claim of a legacy JWT-format key, without verifying it.
  /// Used only to refuse a service-role key. Returns null for anything else.
  static String? _jwtRole(String key) {
    final parts = key.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final claims = jsonDecode(payload);
      return claims is Map ? claims['role'] as String? : null;
    } on Object {
      return null;
    }
  }
}

/// Result of [SupabaseConfig.validate]: either a config or a safe message.
class SupabaseConfigCheck {
  const SupabaseConfigCheck._ok(SupabaseConfig this.config) : problem = null;
  const SupabaseConfigCheck._problem(String this.problem) : config = null;

  /// The values were valid but the Supabase client failed to start.
  static const SupabaseConfigCheck initializationFailed =
      SupabaseConfigCheck._problem(
    'Supabase sign-in could not be started. Check the configured URL and '
    'publishable key, then restart the app.',
  );

  final SupabaseConfig? config;

  /// Safe to show in the UI. Never contains the key.
  final String? problem;

  bool get isConfigured => config != null;
}
