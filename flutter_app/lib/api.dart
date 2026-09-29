import 'dart:convert';
import 'package:http/http.dart' as http;

/// ============================================================
/// IMPORTANT: SET THIS TO YOUR MACHINE'S LOCAL IP ADDRESS
/// ============================================================
/// The Android emulator's 10.0.2.2 often gets blocked by Windows
/// Firewall. The most reliable approach is to use your PC's actual
/// LAN IP address instead.
///
/// To find it: open CMD → type "ipconfig" → look for
/// "IPv4 Address" under your Wi-Fi or Ethernet adapter.
/// Example: 192.168.1.5
///
/// Then set: const String kBaseUrl = 'http://192.168.1.5:8000';
///
/// Quick options:
///   Android emulator:  http://10.0.2.2:8000  (often blocked)
///   Better for emu:    http://<your-PC-IP>:8000
///   Chrome / Desktop:  http://127.0.0.1:8000
/// ============================================================
const String kBaseUrl = 'http://192.168.1.3:8000';

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

class Api {
  /// Timeout set to 10s so the UI doesn't hang forever.
  static const _timeout = Duration(seconds: 10);

  static Future<PatientRecord> getPatient(String cnic) async {
    final r = await http
        .get(Uri.parse('$kBaseUrl/api/patient/$cnic'))
        .timeout(_timeout);
    if (r.statusCode == 404) throw Exception('No patient found for that CNIC.');
    if (r.statusCode != 200) throw Exception('Server error (${r.statusCode}).');
    final j = jsonDecode(r.body);
    return PatientRecord(
      PatientSummary.fromJson(j['summary']),
      (j['alerts'] as List).map((e) => Alert.fromJson(e)).toList(),
    );
  }

  static Future<List<Map<String, dynamic>>> samplePatients() async {
    final r = await http
        .get(Uri.parse('$kBaseUrl/api/patients/sample?n=8'))
        .timeout(_timeout);
    return (jsonDecode(r.body) as List).cast<Map<String, dynamic>>();
  }

  static Future<String> chat(String cnic, String message) async {
    final r = await http
        .post(
          Uri.parse('$kBaseUrl/api/chat'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'cnic': cnic, 'message': message}),
        )
        .timeout(_timeout);
    return jsonDecode(r.body)['reply'] ?? '';
  }

  static Future<DashboardStats> getStats() async {
    final r = await http
        .get(Uri.parse('$kBaseUrl/api/stats'))
        .timeout(_timeout);
    return DashboardStats.fromJson(jsonDecode(r.body));
  }

  static Future<List<Map<String, dynamic>>> criticalPatients(
      {int limit = 20}) async {
    final r = await http
        .get(Uri.parse('$kBaseUrl/api/dashboard/critical?limit=$limit'))
        .timeout(_timeout);
    return (jsonDecode(r.body) as List).cast<Map<String, dynamic>>();
  }

  /// Quick connectivity check.
  static Future<bool> ping() async {
    try {
      final r = await http.get(Uri.parse('$kBaseUrl/')).timeout(
          const Duration(seconds: 5));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
