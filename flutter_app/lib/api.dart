import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// ============================================================
/// BACKEND URL CONFIGURATION
/// ============================================================
/// The API base URL is supplied at build time, so no machine-specific
/// address has to be edited into source:
///
///   flutter run --dart-define=NEMRAS_API_URL=http://192.168.1.5:8000
///   flutter build apk --dart-define=NEMRAS_API_URL=https://api.nemras.pk
///
/// Quick options:
///   Chrome / Desktop:  http://127.0.0.1:8000
///   Android emulator:  http://10.0.2.2:8000  (often blocked by Windows Firewall)
///   Physical phone:    http://<your-PC-LAN-IP>:8000  (same Wi-Fi as the PC)
///
/// To find your LAN IP: open CMD → type "ipconfig" → look for
/// "IPv4 Address" under your Wi-Fi or Ethernet adapter.
///
/// [kDefaultApiUrl] is the development fallback used when no
/// --dart-define is passed. It keeps the existing local workflow working.
/// ============================================================
const String kDefaultApiUrl = 'http://192.168.1.3:8000';

/// Build-time API base URL. Override with
/// `--dart-define=NEMRAS_API_URL=http://host:port`.
const String kBaseUrl = String.fromEnvironment(
  'NEMRAS_API_URL',
  defaultValue: kDefaultApiUrl,
);

/// Why an API call failed. Lets the UI react to the cause instead of
/// pattern-matching on exception text.
enum ApiErrorKind {
  /// Host unreachable, DNS failure, backend not running.
  network,

  /// Request exceeded [Api.timeout].
  timeout,

  /// 404 - the requested record does not exist.
  notFound,

  /// 401 - the access token was missing, expired or rejected.
  unauthorized,

  /// 4xx other than 404 - the request itself was rejected.
  badRequest,

  /// 5xx, including 503 when the backend has no dataset loaded.
  server,

  /// 2xx response whose body was not the expected JSON shape.
  decode,
}

/// Typed error raised by every [Api] method.
class ApiException implements Exception {
  final ApiErrorKind kind;

  /// Message safe to show to a user. Never contains patient data.
  final String message;

  /// HTTP status code, when the failure came from a response.
  final int? statusCode;

  const ApiException(this.kind, this.message, {this.statusCode});

  /// True when retrying later could plausibly succeed.
  bool get isConnectivityIssue =>
      kind == ApiErrorKind.network || kind == ApiErrorKind.timeout;

  @override
  String toString() => message;
}

class PatientSummary {
  final String cnic, patientName, gender, bloodType, medicalCondition;
  final String medication, allergy, chronicCondition, drugInteractionRisk;
  final String triageLevel, riskScore, admissionType, testResults, hospital;
  final String doctor, insuranceProvider, admissionDate, dischargeDate;
  final int age;

  PatientSummary.fromJson(Map<String, dynamic> j)
      : cnic = j['cnic'] ?? '',
        patientName = j['patient_name'] ?? '',
        age = j['age'] ?? 0,
        gender = j['gender'] ?? '',
        bloodType = j['blood_type'] ?? '',
        medicalCondition = j['medical_condition'] ?? '',
        medication = j['medication'] ?? '',
        allergy = j['allergy'] ?? 'None',
        chronicCondition = j['chronic_condition'] ?? 'No',
        drugInteractionRisk = j['drug_interaction_risk'] ?? 'No',
        triageLevel = j['triage_level'] ?? '',
        riskScore = j['risk_score'] ?? '',
        admissionType = j['admission_type'] ?? '',
        testResults = j['test_results'] ?? '',
        hospital = j['hospital'] ?? '',
        doctor = j['doctor'] ?? '',
        insuranceProvider = j['insurance_provider'] ?? '',
        admissionDate = j['admission_date'] ?? '',
        dischargeDate = j['discharge_date'] ?? '';
}

class Alert {
  final String severity, title, detail;
  Alert.fromJson(Map<String, dynamic> j)
      : severity = j['severity'] ?? 'info',
        title = j['title'] ?? '',
        detail = j['detail'] ?? '';
}

class PatientRecord {
  final PatientSummary summary;
  final List<Alert> alerts;
  PatientRecord(this.summary, this.alerts);
}

class DashboardStats {
  final int totalPatients;
  final Map<String, int> riskScore, triageLevel, medicalCondition, admissionType;
  final double avgAge;

  DashboardStats.fromJson(Map<String, dynamic> j)
      : totalPatients = j['total_patients'] ?? 0,
        avgAge = (j['avg_age'] ?? 0).toDouble(),
        riskScore = _toIntMap(j['risk_score']),
        triageLevel = _toIntMap(j['triage_level']),
        medicalCondition = _toIntMap(j['medical_condition']),
        admissionType = _toIntMap(j['admission_type']);

  static Map<String, int> _toIntMap(dynamic m) {
    if (m == null) return {};
    return (m as Map).map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
  }
}

/// The caller's NEMRAS Patient ID, from `POST /api/v1/me/patient-id`.
///
/// Not bound to a CNIC and grants no access to any patient record.
class IssuedPatientId {
  final String nemrasId, displayId, status, createdAt, bindingStatus;
  final bool newlyIssued;

  IssuedPatientId.fromJson(Map<String, dynamic> j)
      : nemrasId = j['nemras_id'] as String,
        displayId = j['display_id'] as String,
        status = j['status'] as String,
        createdAt = j['created_at'] as String,
        bindingStatus = j['binding_status'] as String,
        newlyIssued = j['newly_issued'] as bool;
}

class Api {
  /// Timeout set to 10s so the UI doesn't hang forever.
  static const timeout = Duration(seconds: 10);

  /// Maps a non-2xx response onto a typed [ApiException].
  ///
  /// The server's `detail` field is deliberately not echoed back verbatim:
  /// it can contain the requested CNIC.
  static ApiException errorForStatus(int statusCode, {String? notFoundMessage}) {
    if (statusCode == 401) {
      return ApiException(
        ApiErrorKind.unauthorized,
        'Your session has expired or is not valid. Sign in again.',
        statusCode: statusCode,
      );
    }
    if (statusCode == 404) {
      return ApiException(
        ApiErrorKind.notFound,
        notFoundMessage ?? 'Record not found.',
        statusCode: statusCode,
      );
    }
    if (statusCode == 503) {
      return ApiException(
        ApiErrorKind.server,
        'The NEMRAS service is starting up or unavailable. Try again shortly.',
        statusCode: statusCode,
      );
    }
    if (statusCode >= 500) {
      return ApiException(
        ApiErrorKind.server,
        'Server error ($statusCode). Please try again.',
        statusCode: statusCode,
      );
    }
    if (statusCode >= 400) {
      return ApiException(
        ApiErrorKind.badRequest,
        'Request rejected ($statusCode). Check the details and try again.',
        statusCode: statusCode,
      );
    }
    return ApiException(
      ApiErrorKind.server,
      'Unexpected response ($statusCode).',
      statusCode: statusCode,
    );
  }

  /// Single funnel for every request: checks the status code, decodes the
  /// body, and converts transport/parse failures into [ApiException].
  static Future<T> _send<T>(
    Future<http.Response> Function() request,
    T Function(dynamic json) parse, {
    String? notFoundMessage,
  }) async {
    final http.Response response;
    try {
      response = await request().timeout(timeout);
    } on TimeoutException {
      throw const ApiException(
        ApiErrorKind.timeout,
        'The request timed out. Check that the NEMRAS backend is reachable.',
      );
    } catch (_) {
      // Not narrowed to SocketException: dart:io cannot be imported here
      // without breaking the Flutter Web build.
      throw const ApiException(
        ApiErrorKind.network,
        'Cannot reach the NEMRAS backend. Check the server and NEMRAS_API_URL.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw errorForStatus(response.statusCode,
          notFoundMessage: notFoundMessage);
    }

    try {
      return parse(jsonDecode(response.body));
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        ApiErrorKind.decode,
        'The server returned an unexpected response format.',
      );
    }
  }

  static Future<PatientRecord> getPatient(String cnic) {
    return _send(
      () => http.get(Uri.parse('$kBaseUrl/api/patient/$cnic')),
      (j) => PatientRecord(
        PatientSummary.fromJson(j['summary'] as Map<String, dynamic>),
        (j['alerts'] as List)
            .map((e) => Alert.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      notFoundMessage: 'No patient found for that CNIC.',
    );
  }

  static Future<List<Map<String, dynamic>>> samplePatients() {
    return _send(
      () => http.get(Uri.parse('$kBaseUrl/api/patients/sample?n=8')),
      (j) => (j as List).cast<Map<String, dynamic>>(),
    );
  }

  static Future<String> chat(String cnic, String message) {
    return _send(
      () => http.post(
        Uri.parse('$kBaseUrl/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'cnic': cnic, 'message': message}),
      ),
      (j) => (j['reply'] as String?) ?? '',
      notFoundMessage: 'That record is no longer available.',
    );
  }

  static Future<DashboardStats> getStats() {
    return _send(
      () => http.get(Uri.parse('$kBaseUrl/api/stats')),
      (j) => DashboardStats.fromJson(j as Map<String, dynamic>),
    );
  }

  static Future<List<Map<String, dynamic>>> criticalPatients(
      {int limit = 20}) {
    return _send(
      () => http.get(Uri.parse('$kBaseUrl/api/dashboard/critical?limit=$limit')),
      (j) => (j as List).cast<Map<String, dynamic>>(),
    );
  }

  /// Issues, or returns, the signed-in user's NEMRAS Patient ID.
  ///
  /// [accessToken] goes only into the Authorization header and is never
  /// logged. [client] exists for tests.
  static Future<IssuedPatientId> issueMyPatientId({
    required String accessToken,
    http.Client? client,
  }) {
    final uri = Uri.parse('$kBaseUrl/api/v1/me/patient-id');
    final headers = {'Authorization': 'Bearer $accessToken'};
    return _send(
      () => client != null
          ? client.post(uri, headers: headers)
          : http.post(uri, headers: headers),
      (j) => IssuedPatientId.fromJson(j as Map<String, dynamic>),
    );
  }

  /// Quick connectivity check. Returns false rather than throwing, since
  /// callers only use it to show the offline banner.
  static Future<bool> ping() async {
    try {
      final r = await http
          .get(Uri.parse('$kBaseUrl/'))
          .timeout(const Duration(seconds: 5));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
