import 'package:flutter/foundation.dart';

/// The administrative roles this dashboard renders for.
///
/// Navigation and presentation scope only. It grants no authorisation: the
/// NEMRAS backend remains the security boundary.
enum OpsRole {
  hospitalAdministrator,
  operationsManager,
  hospitalSupervisor,
}

extension OpsRoleLabel on OpsRole {
  String get label {
    switch (this) {
      case OpsRole.hospitalAdministrator:
        return 'Hospital Administrator';
      case OpsRole.operationsManager:
        return 'Operations Manager';
      case OpsRole.hospitalSupervisor:
        return 'Hospital Supervisor';
    }
  }

  String get shortLabel {
    switch (this) {
      case OpsRole.hospitalAdministrator:
        return 'ADMINISTRATOR';
      case OpsRole.operationsManager:
        return 'OPERATIONS MANAGER';
      case OpsRole.hospitalSupervisor:
        return 'SUPERVISOR';
    }
  }
}

/// Which build this is. Shown in the top bar and on Settings so a reviewer
/// can never mistake a demo session for a production one.
enum OpsEnvironment { demo, production }

extension OpsEnvironmentLabel on OpsEnvironment {
  String get label =>
      this == OpsEnvironment.demo ? 'DEMO' : 'PRODUCTION';

  bool get isDemo => this == OpsEnvironment.demo;
}

/// An administrative staff identity.
///
/// In production [firebaseUid] is the Firebase Authentication UID and the
/// backend resolves [staffId] from it. Phase 4A supplies a labelled demo
/// identity; it is not a credential and authorises nothing.
@immutable
class HospitalAdminProfile {
  const HospitalAdminProfile({
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
  final OpsRole role;
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

/// The hospital this build is scoped to.
///
/// `Hospital` in `NEMRAS_Dataset.csv` is a free-text name rather than an id,
/// so the hospital id is a NEMRAS-side identifier and is labelled demo.
@immutable
class OpsHospitalIdentity {
  const OpsHospitalIdentity({
    required this.hospitalId,
    required this.displayName,
    required this.region,
    required this.isDemo,
  });

  final String hospitalId;
  final String displayName;
  final String region;
  final bool isDemo;
}

/// Demo identifiers approved for Phase 4A. Not production credentials.
abstract final class DemoOpsIdentity {
  static const String hospitalId = 'HOSP-001';

  static const OpsHospitalIdentity hospital = OpsHospitalIdentity(
    hospitalId: hospitalId,
    displayName: 'NEMRAS Demo Hospital',
    region: 'Demo Region',
    isDemo: true,
  );

  static const HospitalAdminProfile administrator = HospitalAdminProfile(
    firebaseUid: 'DEMO-ADMIN-UID',
    staffId: 'ADMIN-001',
    hospitalId: hospitalId,
    displayLabel: 'Demo Hospital Administrator',
    role: OpsRole.hospitalAdministrator,
    isDemo: true,
  );

  static const HospitalAdminProfile operationsManager = HospitalAdminProfile(
    firebaseUid: 'DEMO-ADMIN-UID',
    staffId: 'ADMIN-002',
    hospitalId: hospitalId,
    displayLabel: 'Demo Operations Manager',
    role: OpsRole.operationsManager,
    isDemo: true,
  );

  static const HospitalAdminProfile supervisor = HospitalAdminProfile(
    firebaseUid: 'DEMO-ADMIN-UID',
    staffId: 'ADMIN-003',
    hospitalId: hospitalId,
    displayLabel: 'Demo Hospital Supervisor',
    role: OpsRole.hospitalSupervisor,
    isDemo: true,
  );

  static HospitalAdminProfile forRole(OpsRole role) {
    switch (role) {
      case OpsRole.hospitalAdministrator:
        return administrator;
      case OpsRole.operationsManager:
        return operationsManager;
      case OpsRole.hospitalSupervisor:
        return supervisor;
    }
  }
}
