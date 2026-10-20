import 'package:flutter/foundation.dart';

/// Placeholder shown wherever NEMRAS holds no value for a field.
///
/// The data rules forbid substituting a plausible clinical value for a missing
/// one, so every null or blank field renders this instead.
const String kNotAvailable = 'Not available';

String _text(dynamic value) {
  if (value == null) return kNotAvailable;
  final text = value.toString().trim();
  return text.isEmpty ? kNotAvailable : text;
}

/// The Critical Health Summary returned by `GET /api/patient/{cnic}`.
///
/// Every field here exists in `NEMRAS_Dataset.csv`. Nothing is derived,
/// inferred or invented: no vitals, no numeric laboratory panels, no ICD
/// codes. [testResults] is the dataset's own categorical label, not a panel.
@immutable
class PatientClinicalSummary {
  const PatientClinicalSummary({
    required this.cnic,
    required this.patientName,
    required this.age,
    required this.gender,
    required this.bloodType,
    required this.medicalCondition,
    required this.medication,
    required this.allergy,
    required this.chronicCondition,
    required this.drugInteractionRisk,
    required this.triageLevel,
    required this.riskScore,
    required this.admissionType,
    required this.admissionDate,
    required this.dischargeDate,
    required this.testResults,
    required this.hospital,
    required this.doctor,
    required this.insuranceProvider,
  });

  factory PatientClinicalSummary.fromJson(Map<String, dynamic> json) {
    final rawAge = json['age'];
    return PatientClinicalSummary(
      cnic: _text(json['cnic']),
      patientName: _text(json['patient_name']),
      age: rawAge is num ? rawAge.toInt() : null,
      gender: _text(json['gender']),
      bloodType: _text(json['blood_type']),
      medicalCondition: _text(json['medical_condition']),
      medication: _text(json['medication']),
      allergy: _text(json['allergy']),
      chronicCondition: _text(json['chronic_condition']),
      drugInteractionRisk: _text(json['drug_interaction_risk']),
      triageLevel: _text(json['triage_level']),
      riskScore: _text(json['risk_score']),
      admissionType: _text(json['admission_type']),
      admissionDate: _text(json['admission_date']),
      dischargeDate: _text(json['discharge_date']),
      testResults: _text(json['test_results']),
      hospital: _text(json['hospital']),
      doctor: _text(json['doctor']),
      insuranceProvider: _text(json['insurance_provider']),
    );
  }

  final String cnic;
  final String patientName;

  /// Null when the dataset carries no age for this record.
  final int? age;
  final String gender;
  final String bloodType;
  final String medicalCondition;
  final String medication;
  final String allergy;

  /// Recorded only as `Yes`/`No`. The dataset carries no severity grading.
  final String chronicCondition;

  /// Recorded only as `Yes`/`No`.
  final String drugInteractionRisk;

  /// `High` / `Medium` / `Low`.
  final String triageLevel;

  /// `Critical` / `Elevated` / `Stable`.
  ///
  /// A categorical label carried in the dataset, not a model probability.
  /// Never render this as a percentage or a score.
  final String riskScore;
  final String admissionType;
  final String admissionDate;
  final String dischargeDate;
  final String testResults;
  final String hospital;
  final String doctor;
  final String insuranceProvider;

  String get ageLabel => age == null ? kNotAvailable : '$age';

  bool get hasRecordedAllergy =>
      allergy != kNotAvailable && allergy.toLowerCase() != 'none';

  bool get hasDrugInteractionFlag =>
      drugInteractionRisk.toLowerCase() == 'yes';

  bool get hasChronicCondition => chronicCondition.toLowerCase() == 'yes';
}

/// A rule-based alert emitted by the NEMRAS backend.
///
/// The backend derives these from the record with explicit `if` rules. They
/// are not the output of a trained model.
@immutable
class ClinicalAlert {
  const ClinicalAlert({
    required this.severity,
    required this.title,
    required this.detail,
  });

  factory ClinicalAlert.fromJson(Map<String, dynamic> json) => ClinicalAlert(
        severity: _text(json['severity']).toLowerCase(),
        title: _text(json['title']),
        detail: _text(json['detail']),
      );

  /// `critical` / `high` / `info`.
  final String severity;
  final String title;
  final String detail;
}

/// A patient record as the clinical desktop consumes it.
@immutable
class PatientClinicalRecord {
  const PatientClinicalRecord({
    required this.summary,
    required this.alerts,
  });

  factory PatientClinicalRecord.fromJson(Map<String, dynamic> json) {
    final alerts = json['alerts'];
    return PatientClinicalRecord(
      summary: PatientClinicalSummary.fromJson(
        (json['summary'] as Map).cast<String, dynamic>(),
      ),
      alerts: <ClinicalAlert>[
        if (alerts is List)
          for (final alert in alerts)
            ClinicalAlert.fromJson((alert as Map).cast<String, dynamic>()),
      ],
    );
  }

  final PatientClinicalSummary summary;
  final List<ClinicalAlert> alerts;
}

/// A row from `GET /api/dashboard/critical`.
///
/// This is a dataset ordering by risk tier, not a live admissions feed.
@immutable
class CriticalPatientRow {
  const CriticalPatientRow({
    required this.cnic,
    required this.patientName,
    required this.age,
    required this.medicalCondition,
    required this.triageLevel,
    required this.riskScore,
    required this.admissionType,
    required this.hospital,
  });

  factory CriticalPatientRow.fromJson(Map<String, dynamic> json) {
    final rawAge = json['Age'];
    return CriticalPatientRow(
      cnic: _text(json['CNIC']),
      patientName: _text(json['Patient_Name']),
      age: rawAge is num ? rawAge.toInt() : null,
      medicalCondition: _text(json['Medical_Condition']),
      triageLevel: _text(json['Triage_Level']),
      riskScore: _text(json['Risk_Score']),
      admissionType: _text(json['Admission_Type']),
      hospital: _text(json['Hospital']),
    );
  }

  final String cnic;
  final String patientName;
  final int? age;
  final String medicalCondition;
  final String triageLevel;
  final String riskScore;
  final String admissionType;
  final String hospital;

  String get ageLabel => age == null ? kNotAvailable : '$age';
}

/// Population counts from `GET /api/stats`.
///
/// These describe the NEMRAS dataset. They are not live hospital telemetry and
/// carry no bed, occupancy or staffing information, because NEMRAS records
/// none.
@immutable
class ClinicalPopulationStats {
  const ClinicalPopulationStats({
    required this.totalPatients,
    required this.averageAge,
    required this.riskScore,
    required this.triageLevel,
    required this.medicalCondition,
    required this.admissionType,
    required this.drugInteractionRisk,
    required this.chronicCondition,
  });

  factory ClinicalPopulationStats.fromJson(Map<String, dynamic> json) {
    final total = json['total_patients'];
    final average = json['avg_age'];
    return ClinicalPopulationStats(
      totalPatients: total is num ? total.toInt() : 0,
      averageAge: average is num ? average.toDouble() : null,
      riskScore: _counts(json['risk_score']),
      triageLevel: _counts(json['triage_level']),
      medicalCondition: _counts(json['medical_condition']),
      admissionType: _counts(json['admission_type']),
      drugInteractionRisk: _counts(json['drug_interaction_risk']),
      chronicCondition: _counts(json['chronic_condition']),
    );
  }

  static Map<String, int> _counts(dynamic value) {
    if (value is! Map) return const <String, int>{};
    return <String, int>{
      for (final entry in value.entries)
        if (entry.value is num)
          entry.key.toString(): (entry.value as num).toInt(),
    };
  }

  final int totalPatients;
  final double? averageAge;
  final Map<String, int> riskScore;
  final Map<String, int> triageLevel;
  final Map<String, int> medicalCondition;
  final Map<String, int> admissionType;
  final Map<String, int> drugInteractionRisk;
  final Map<String, int> chronicCondition;

  int countFor(Map<String, int> breakdown, String label) =>
      breakdown[label] ?? 0;

  String get averageAgeLabel =>
      averageAge == null ? kNotAvailable : averageAge!.toStringAsFixed(1);

  /// The highest-count conditions, largest first. Used for the overview
  /// breakdown panel rather than an invented chart series.
  List<({String label, int count})> topConditions({int limit = 6}) {
    final entries = medicalCondition.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return <({String label, int count})>[
      for (final entry in entries.take(limit))
        (label: entry.key, count: entry.value),
    ];
  }
}
