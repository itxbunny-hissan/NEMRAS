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

enum NationalApiErrorKind { network, timeout, server, decode }

class NationalApiException implements Exception {
  const NationalApiException(this.kind, this.message, {this.statusCode});

  final NationalApiErrorKind kind;

  /// Safe to display. The backend's own `detail` field is never forwarded.
  final String message;
  final int? statusCode;

  bool get isConnectivityIssue =>
      kind == NationalApiErrorKind.network ||
      kind == NationalApiErrorKind.timeout;

  @override
  String toString() => message;
}

/// Reads national aggregate figures from the NEMRAS backend.
///
/// Deliberately narrow, and narrower than the hospital clients: this surface
/// needs population counts, one bounded slice and a health probe. It has no
/// patient-lookup call, no chat call and no identity call, because a national
/// analytics surface has no authorised use for an individual record.
///
/// `GET /api/dashboard/critical` is the one route here that returns
/// patient-level rows. It is used only because it is the sole per-record
/// source available, and the response is reduced to categorical fields at the
/// parse boundary in `RiskSampleRow.fromJson`, so no identifier ever reaches
/// the widget layer. Replacing it with a true aggregate endpoint is the
/// recommendation recorded in the phase report.
class NationalApiClient {
  NationalApiClient({http.Client? httpClient, String? baseUrl})
      : _http = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? kBaseUrl;

  static const Duration timeout = Duration(seconds: 10);

  final http.Client _http;
  final String _baseUrl;

  String get baseUrl => _baseUrl;

  Future<T> _get<T>(String path, T Function(dynamic json) parse) async {
    final http.Response response;
    try {
      response = await _http.get(Uri.parse('$_baseUrl$path')).timeout(timeout);
    } on TimeoutException {
      throw const NationalApiException(
        NationalApiErrorKind.timeout,
        'The request timed out. Check that the NEMRAS backend is reachable.',
      );
    } catch (_) {
      // Not narrowed to SocketException: dart:io cannot be imported here
      // without breaking the web build.
      throw const NationalApiException(
        NationalApiErrorKind.network,
        'Cannot reach the NEMRAS backend. Check the server and '
        'NEMRAS_API_URL.',
      );
    }

    if (response.statusCode == 503) {
      throw const NationalApiException(
        NationalApiErrorKind.server,
        'The NEMRAS backend has no dataset loaded, so no national figures '
        'can be reported.',
        statusCode: 503,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw NationalApiException(
        NationalApiErrorKind.server,
        'The NEMRAS backend returned ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    }

    try {
      return parse(jsonDecode(response.body));
    } on NationalApiException {
      rethrow;
    } catch (_) {
      throw const NationalApiException(
        NationalApiErrorKind.decode,
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
    } on NationalApiException {
      return null;
    }
  }

  void dispose() => _http.close();
}
