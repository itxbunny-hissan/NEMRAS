import 'package:flutter/foundation.dart';

/// The clinical roles the hospital desktop renders for.
///
/// This is presentation and navigation scope only. It carries no
/// authorisation: the NEMRAS backend remains the security boundary, and
/// nothing here grants access to a patient record.
enum ClinicalRole {
  emergencyPhysician,
  doctor,
  nurse,
}

extension ClinicalRoleLabel on ClinicalRole {
  String get label {
    switch (this) {
      case ClinicalRole.emergencyPhysician:
        return 'Emergency Physician';
      case ClinicalRole.doctor:
        return 'Doctor';
      case ClinicalRole.nurse:
        return 'Nurse — Clinical Staff';
    }
  }

  /// Short form for the top bar, where horizontal space is tight.
  String get shortLabel {
    switch (this) {
      case ClinicalRole.emergencyPhysician:
        return 'EMERGENCY PHYSICIAN';
      case ClinicalRole.doctor:
        return 'DOCTOR';
      case ClinicalRole.nurse:
        return 'NURSE';
    }
  }
}

/// A clinical staff identity.
///
/// In production [firebaseUid] is the Firebase Authentication UID and the
/// backend resolves [staffId] from it. Phase 3A supplies a clearly labelled
/// demo identity instead; it is never a credential and grants nothing.
@immutable
class HospitalStaffProfile {
  const HospitalStaffProfile({
    required this.firebaseUid,
    required this.staffId,
    required this.hospitalId,
    required this.displayLabel,
    required this.role,
    required this.isDemo,
  });

  final String firebaseUid;
  final String staffId;
  final String hospitalId;
  final String displayLabel;
  final ClinicalRole role;
  final bool isDemo;

  /// Initials for the top-bar avatar.
  String get initials {
    final words = displayLabel
        .split(RegExp(r'\s+'))
        .where((w) => RegExp(r'^[A-Za-z]').hasMatch(w))
        .toList();
    if (words.isEmpty) return 'ID';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return (words.first.substring(0, 1) + words.last.substring(0, 1))
        .toUpperCase();
  }
}

/// The hospital this demo build is pinned to.
///
/// `Hospital` values in `NEMRAS_Dataset.csv` are free-text names, not ids, so
/// the demo hospital id is a NEMRAS-side identifier and is labelled DEMO.
@immutable
class HospitalIdentity {
  const HospitalIdentity({
    required this.hospitalId,
    required this.displayName,
    required this.isDemo,
  });

  final String hospitalId;
  final String displayName;
  final bool isDemo;
}

/// Demo identifiers approved for Phase 3A. These are NOT production
/// credentials and authorise nothing.
abstract final class DemoHospitalIdentity {
  static const String hospitalId = 'HOSP-001';

  static const HospitalIdentity hospital = HospitalIdentity(
    hospitalId: hospitalId,
    displayName: 'NEMRAS Demo Hospital',
    isDemo: true,
  );

  static const HospitalStaffProfile physician = HospitalStaffProfile(
    firebaseUid: 'DEMO-STAFF-UID',
    staffId: 'STAFF-001',
    hospitalId: hospitalId,
    displayLabel: 'Demo Emergency Physician',
    role: ClinicalRole.emergencyPhysician,
    isDemo: true,
  );

  static const HospitalStaffProfile doctor = HospitalStaffProfile(
    firebaseUid: 'DEMO-STAFF-UID',
    staffId: 'STAFF-001',
    hospitalId: hospitalId,
    displayLabel: 'Demo Doctor',
    role: ClinicalRole.doctor,
    isDemo: true,
  );

  static const HospitalStaffProfile nurse = HospitalStaffProfile(
    firebaseUid: 'DEMO-STAFF-UID',
    staffId: 'STAFF-001',
    hospitalId: hospitalId,
    displayLabel: 'Demo Clinical Nurse',
    role: ClinicalRole.nurse,
    isDemo: true,
  );

  static HospitalStaffProfile forRole(ClinicalRole role) {
    switch (role) {
      case ClinicalRole.emergencyPhysician:
        return physician;
      case ClinicalRole.doctor:
        return doctor;
      case ClinicalRole.nurse:
        return nurse;
    }
  }
}
