import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hospital_desktop/src/data/clinical_api_client.dart';

/// A synthetic patient payload shaped exactly like the NEMRAS backend's
/// `GET /api/patient/{cnic}` response.
///
/// The CNIC and name are obviously synthetic. No real record is reproduced in
/// the test suite.
Map<String, dynamic> demoPatientPayload({
  String cnic = '00000-0000001-0',
  String riskScore = 'Critical',
  String allergy = 'Penicillin',
  String drugInteractionRisk = 'Yes',
}) {
  return <String, dynamic>{
    'summary': <String, dynamic>{
      'cnic': cnic,
      'patient_name': 'Test Subject One',
      'age': 58,
      'gender': 'Male',
      'blood_type': 'O+',
      'medical_condition': 'Heart Disease',
      'medication': 'Aspirin',
      'allergy': allergy,
      'chronic_condition': 'Yes',
      'drug_interaction_risk': drugInteractionRisk,
      'triage_level': 'High',
      'risk_score': riskScore,
      'admission_type': 'Emergency',
      'admission_date': '2026-01-04',
      'discharge_date': null,
      'test_results': 'Abnormal',
      'hospital': 'Test General',
      'doctor': 'Dr Test',
      'insurance_provider': 'Test Insurance',
    },
    'alerts': <Map<String, dynamic>>[
      <String, dynamic>{
        'severity': 'critical',
        'title': 'Allergy: $allergy',
        'detail': 'Patient has a documented $allergy allergy.',
      },
      <String, dynamic>{
        'severity': 'info',
        'title': 'Chronic: Heart Disease',
        'detail': 'Ongoing chronic condition.',
      },
    ],
  };
}

Map<String, dynamic> demoStatsPayload() {
  return <String, dynamic>{
    'total_patients': 1000,
    'risk_score': <String, int>{
      'Stable': 600,
      'Elevated': 300,
      'Critical': 100,
    },
    'triage_level': <String, int>{'Low': 500, 'Medium': 300, 'High': 200},
    'drug_interaction_risk': <String, int>{'No': 800, 'Yes': 200},
    'medical_condition': <String, int>{
      'Heart Disease': 400,
      'Asthma': 350,
      'Fracture': 250,
    },
    'admission_type': <String, int>{'Emergency': 700, 'Elective': 300},
    'chronic_condition': <String, int>{'No': 700, 'Yes': 300},
    'avg_age': 44.2,
  };
}

List<Map<String, dynamic>> demoCriticalPayload() {
  return <Map<String, dynamic>>[
    <String, dynamic>{
      'CNIC': '00000-0000001-0',
      'Patient_Name': 'Test Subject One',
      'Age': 58,
      'Medical_Condition': 'Heart Disease',
      'Triage_Level': 'High',
      'Risk_Score': 'Critical',
      'Admission_Type': 'Emergency',
      'Hospital': 'Test General',
    },
  ];
}

/// An API client backed by a canned backend, so no test touches the network.
///
/// [patientStatus] lets a test drive the 404 and 503 paths.
ClinicalApiClient fakeApiClient({
  int patientStatus = 200,
  int chatStatus = 200,
  Map<String, dynamic>? patient,
  bool reachable = true,
  String chatReply = 'Your records list a Penicillin allergy.',
}) {
  final payload = patient ?? demoPatientPayload();

  final client = MockClient((http.Request request) async {
    final path = request.url.path;

    if (path == '/') {
      return reachable
          ? http.Response(jsonEncode(<String, dynamic>{'status': 'ok'}), 200)
          : http.Response('', 503);
    }
    if (path.startsWith('/api/patient/')) {
      if (patientStatus != 200) {
        return http.Response(
          jsonEncode(<String, String>{'detail': 'not found'}),
          patientStatus,
        );
      }
      return http.Response(jsonEncode(payload), 200,
          headers: <String, String>{'content-type': 'application/json'});
    }
    if (path == '/api/stats') {
      return http.Response(jsonEncode(demoStatsPayload()), 200);
    }
    if (path == '/api/dashboard/critical') {
      return http.Response(jsonEncode(demoCriticalPayload()), 200);
    }
    if (path == '/api/patients/sample') {
      return http.Response(jsonEncode(demoCriticalPayload()), 200);
    }
    if (path == '/api/chat') {
      if (chatStatus != 200) return http.Response('', chatStatus);
      return http.Response(
        jsonEncode(<String, String>{'reply': chatReply}),
        200,
      );
    }
    return http.Response('', 404);
  });

  return ClinicalApiClient(
    httpClient: client,
    baseUrl: 'http://backend.test',
  );
}

/// An API client whose every request fails at the transport layer.
ClinicalApiClient offlineApiClient() {
  final client = MockClient((http.Request request) async {
    throw http.ClientException('connection refused');
  });
  return ClinicalApiClient(
    httpClient: client,
    baseUrl: 'http://backend.test',
  );
}
