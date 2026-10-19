import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Development fallback. Override per build with
/// `--dart-define=NEMRAS_API_URL=http://host:port`.
const String kDefaultApiUrl = 'http://127.0.0.1:8000';

const String kBaseUrl = String.fromEnvironment(
  'NEMRAS_API_URL',
  defaultValue: kDefaultApiUrl,
);

enum OpsApiErrorKind { network, timeout, server, decode }

class OpsApiException implements Exception {
  const OpsApiException(this.kind, this.message, {this.statusCode});

  final OpsApiErrorKind kind;

  /// Safe to display. The dashboard only reads aggregates, but the backend's
  /// `detail` field is still not forwarded, as a standing rule.
  final String message;
  final int? statusCode;

  bool get isConnectivityIssue =>
      kind == OpsApiErrorKind.network || kind == OpsApiErrorKind.timeout;

  @override
  String toString() => message;
}

/// Reads aggregate operational figures from the NEMRAS backend.
///
/// Deliberately narrow: this dashboard needs population counts, a bounded
/// highest-risk slice and a health probe. It has no patient-lookup, chat or
/// identity call, because an operations surface has no business holding a
/// patient record. It sends no credential and claims no authentication; the
/// unversioned routes it reads are unauthenticated, which is a known and
/// separately reported gap.
class OpsApiClient {
  OpsApiClient({http.Client? httpClient, String? baseUrl})
      : _http = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? kBaseUrl;

  static const Duration timeout = Duration(seconds: 10);

  final http.Client _http;
  final String _baseUrl;

  String get baseUrl => _baseUrl;

  Future<T> _get<T>(
    String path,
    T Function(dynamic json) parse,
  ) async {
    final http.Response response;
    try {
      response = await _http.get(Uri.parse('$_baseUrl$path')).timeout(timeout);
    } on TimeoutException {
      throw const OpsApiException(
        OpsApiErrorKind.timeout,
        'The request timed out. Check that the NEMRAS backend is reachable.',
      );
    } catch (_) {
      // Not narrowed to SocketException: dart:io cannot be imported here
      // without breaking the web build.
      throw const OpsApiException(
        OpsApiErrorKind.network,
        'Cannot reach the NEMRAS backend. Check the server and '
        'NEMRAS_API_URL.',
      );
    }

    if (response.statusCode == 503) {
      throw const OpsApiException(
        OpsApiErrorKind.server,
        'The NEMRAS backend has no dataset loaded, so no operational '
        'figures can be reported.',
        statusCode: 503,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OpsApiException(
        OpsApiErrorKind.server,
        'The NEMRAS backend returned ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    }

    try {
      return parse(jsonDecode(response.body));
    } on OpsApiException {
      rethrow;
    } catch (_) {
      throw const OpsApiException(
        OpsApiErrorKind.decode,
        'The backend returned an unexpected response format.',
      );
    }
  }

  Future<Map<String, dynamic>> fetchStats() =>
      _get('/api/stats', (json) => (json as Map).cast<String, dynamic>());

  Future<List<Map<String, dynamic>>> fetchHighestRisk({required int limit}) {
    return _get(
      '/api/dashboard/critical?limit=$limit',
      (json) => <Map<String, dynamic>>[
        for (final row in json as List) (row as Map).cast<String, dynamic>(),
      ],
    );
  }

  /// Reads `GET /health`, which reports whether the dataset actually loaded.
  ///
  /// Returns null when the backend could not be reached at all, so the caller
  /// can tell "unreachable" from "reachable but degraded".
  Future<Map<String, dynamic>?> fetchHealth() async {
    try {
      return await _get(
        '/health',
        (json) => (json as Map).cast<String, dynamic>(),
      );
    } on OpsApiException {
      return null;
    }
  }

  void dispose() => _http.close();
}
