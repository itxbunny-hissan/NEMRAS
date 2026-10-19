import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'clinical_models.dart';

/// Development fallback. Override per build with
/// `--dart-define=NEMRAS_API_URL=http://host:port`.
const String kDefaultApiUrl = 'http://127.0.0.1:8000';

const String kBaseUrl = String.fromEnvironment(
  'NEMRAS_API_URL',
  defaultValue: kDefaultApiUrl,
);

/// Why a request failed, so the UI can react to the cause rather than parse
/// exception text.
enum ClinicalApiErrorKind {
  network,
  timeout,
  notFound,
  badRequest,
  server,
  decode,
}

class ClinicalApiException implements Exception {
  const ClinicalApiException(this.kind, this.message, {this.statusCode});

  final ClinicalApiErrorKind kind;

  /// Safe to display. Never contains patient data: the backend's `detail`
  /// field echoes the requested CNIC, so it is deliberately not forwarded.
  final String message;
  final int? statusCode;

  bool get isConnectivityIssue =>
      kind == ClinicalApiErrorKind.network ||
      kind == ClinicalApiErrorKind.timeout;

  @override
  String toString() => message;
}

/// Reads the NEMRAS backend for the clinical desktop.
///
/// This talks to the existing unversioned routes and changes none of them.
/// Those routes are not authenticated yet, which is a known and separately
/// reported gap; this client does not claim otherwise and sends no credential.
///
/// It duplicates a little of `flutter_app/lib/api.dart` because `flutter_app`
/// is an application rather than a package and cannot be imported. Promoting
/// the shared pieces into a `nemras_core` package is a candidate for a later
/// phase.
class ClinicalApiClient {
  ClinicalApiClient({http.Client? httpClient, String? baseUrl})
      : _http = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? kBaseUrl;

  static const Duration timeout = Duration(seconds: 10);

  final http.Client _http;
  final String _baseUrl;

  static ClinicalApiException errorForStatus(
    int statusCode, {
    String? notFoundMessage,
  }) {
    if (statusCode == 404) {
      return ClinicalApiException(
        ClinicalApiErrorKind.notFound,
        notFoundMessage ?? 'Record not found.',
        statusCode: statusCode,
      );
    }
    if (statusCode == 503) {
      return ClinicalApiException(
        ClinicalApiErrorKind.server,
        'The NEMRAS service is starting up or has no dataset loaded.',
        statusCode: statusCode,
      );
    }
    if (statusCode >= 500) {
      return ClinicalApiException(
        ClinicalApiErrorKind.server,
        'Server error ($statusCode). Try again.',
        statusCode: statusCode,
      );
    }
    if (statusCode >= 400) {
      return ClinicalApiException(
        ClinicalApiErrorKind.badRequest,
        'Request rejected ($statusCode).',
        statusCode: statusCode,
      );
    }
    return ClinicalApiException(
      ClinicalApiErrorKind.server,
      'Unexpected response ($statusCode).',
      statusCode: statusCode,
    );
  }

  Future<T> _send<T>(
    Future<http.Response> Function() request,
    T Function(dynamic json) parse, {
    String? notFoundMessage,
  }) async {
    final http.Response response;
    try {
      response = await request().timeout(timeout);
    } on TimeoutException {
      throw const ClinicalApiException(
        ClinicalApiErrorKind.timeout,
        'The request timed out. Check that the NEMRAS backend is reachable.',
      );
    } catch (_) {
      // Not narrowed to SocketException: dart:io cannot be imported here
      // without breaking the web build.
      throw const ClinicalApiException(
        ClinicalApiErrorKind.network,
        'Cannot reach the NEMRAS backend. Check the server and '
        'NEMRAS_API_URL.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw errorForStatus(
        response.statusCode,
        notFoundMessage: notFoundMessage,
      );
    }

    try {
      return parse(jsonDecode(response.body));
    } on ClinicalApiException {
      rethrow;
    } catch (_) {
      throw const ClinicalApiException(
        ClinicalApiErrorKind.decode,
        'The server returned an unexpected response format.',
      );
    }
  }

  Future<PatientClinicalRecord> fetchPatient(String cnic) {
    return _send(
      () => _http.get(Uri.parse('$_baseUrl/api/patient/$cnic')),
      (json) => PatientClinicalRecord.fromJson(
        (json as Map).cast<String, dynamic>(),
      ),
      notFoundMessage: 'No patient record found for that CNIC.',
    );
  }

  Future<ClinicalPopulationStats> fetchStats() {
    return _send(
      () => _http.get(Uri.parse('$_baseUrl/api/stats')),
      (json) => ClinicalPopulationStats.fromJson(
        (json as Map).cast<String, dynamic>(),
      ),
    );
  }

  Future<List<CriticalPatientRow>> fetchHighestRisk({int limit = 10}) {
    return _send(
      () => _http.get(
        Uri.parse('$_baseUrl/api/dashboard/critical?limit=$limit'),
      ),
      (json) => <CriticalPatientRow>[
        for (final row in json as List)
          CriticalPatientRow.fromJson((row as Map).cast<String, dynamic>()),
      ],
    );
  }

  /// Sample CNICs the backend exposes so the demo always has a valid lookup.
  Future<List<CriticalPatientRow>> fetchSampleCnics({int limit = 8}) {
    return _send(
      () => _http.get(Uri.parse('$_baseUrl/api/patients/sample?n=$limit')),
      (json) => <CriticalPatientRow>[
        for (final row in json as List)
          CriticalPatientRow.fromJson((row as Map).cast<String, dynamic>()),
      ],
    );
  }

  /// Asks the backend's record-grounded responder a question about one record.
  ///
  /// `POST /api/chat` is a deterministic keyword responder over the patient's
  /// own row. It is not a trained clinical model, not an LLM, and carries no
  /// clinical validation. The UI must present it as such.
  Future<String> askGroundedResponder({
    required String cnic,
    required String message,
  }) {
    return _send(
      () => _http.post(
        Uri.parse('$_baseUrl/api/chat'),
        headers: const <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, String>{'cnic': cnic, 'message': message}),
      ),
      (json) => ((json as Map)['reply'] as String?) ?? '',
      notFoundMessage: 'That record is no longer available.',
    );
  }

  /// Connectivity probe. Returns false instead of throwing, because callers
  /// only use it to drive the system-status indicator.
  Future<bool> ping() async {
    try {
      final response = await _http
          .get(Uri.parse('$_baseUrl/'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void dispose() => _http.close();
}
