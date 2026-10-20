import 'package:flutter/foundation.dart';

/// The national roles this dashboard renders for.
///
/// Presentation scope only. These grant no authorisation: the NEMRAS backend
/// remains the security boundary.
enum AnalystRole {
  ministryAnalyst,
  nationalHealthAdministrator,
  nationalOperationsAnalyst,
}

extension AnalystRoleLabel on AnalystRole {
  String get label {
    switch (this) {
      case AnalystRole.ministryAnalyst:
        return 'Ministry Analyst';
      case AnalystRole.nationalHealthAdministrator:
        return 'National Health Administrator';
      case AnalystRole.nationalOperationsAnalyst:
        return 'National Operations Analyst';
    }
  }

  String get shortLabel {
    switch (this) {
      case AnalystRole.ministryAnalyst:
        return 'MINISTRY ANALYST';
      case AnalystRole.nationalHealthAdministrator:
        return 'HEALTH ADMINISTRATOR';
      case AnalystRole.nationalOperationsAnalyst:
        return 'OPERATIONS ANALYST';
    }
  }

  /// What this role is permitted to see on a correctly configured national
  /// surface. Every role here is aggregate-only, which is the point: no
  /// national role in this phase has any patient-level view at all.
  String get dataScope => 'Aggregate only. No patient-level access.';
}

/// Which build this is. Shown in the top bar and on Settings.
enum NationalEnvironment { demo, production }

extension NationalEnvironmentLabel on NationalEnvironment {
  String get label => this == NationalEnvironment.demo ? 'DEMO' : 'PRODUCTION';

  bool get isDemo => this == NationalEnvironment.demo;
}

/// A national analyst identity.
///
/// In production [firebaseUid] is the Firebase Authentication UID and the
/// backend resolves [analystId] from it. Phase 5A supplies a labelled demo
/// identity; it is not a credential and authorises nothing.
@immutable
class MinistryAnalystProfile {
  const MinistryAnalystProfile({
    required this.firebaseUid,
    required this.analystId,
    required this.organizationId,
    required this.displayLabel,
    required this.role,
    required this.isDemo,
  });

  final String firebaseUid;
  final String analystId;
  final String organizationId;
  final String displayLabel;
  final AnalystRole role;
  final bool isDemo;

  /// Initials for the top-bar avatar.
  String get initials {
    final words = displayLabel
        .split(RegExp(r'\s+'))
        .where((word) => RegExp(r'^[A-Za-z]').hasMatch(word))
        .toList();
    if (words.isEmpty) return 'NA';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return (words.first.substring(0, 1) + words.last.substring(0, 1))
        .toUpperCase();
  }
}

/// The national organisation this build is scoped to.
@immutable
class NationalOrganization {
  const NationalOrganization({
    required this.organizationId,
    required this.displayName,
    required this.isDemo,
  });

  final String organizationId;
  final String displayName;
  final bool isDemo;
}

/// The reporting window a figure is described as covering.
///
/// The dataset carries `Admission_Date` values spanning several years, but no
/// endpoint aggregates by date, so this dashboard cannot actually filter by
/// period. The selector is therefore *not* offered as a live control: the
/// only honest value is the whole dataset, and [ReportingPeriod.datasetWide]
/// is the single option. A period picker that silently returned the same
/// numbers for every selection would be worse than none.
enum ReportingPeriod { datasetWide }

extension ReportingPeriodLabel on ReportingPeriod {
  String get label => 'Full dataset';

  String get detail =>
      'No endpoint aggregates by date, so every figure covers the whole '
      'dataset rather than a selected window.';
}

/// Demo identifiers approved for Phase 5A. Not production credentials.
abstract final class DemoMinistryIdentity {
  static const String organizationId = 'MINISTRY-001';

  static const NationalOrganization organization = NationalOrganization(
    organizationId: organizationId,
    displayName: 'NEMRAS National Demo Authority',
    isDemo: true,
  );

  static const MinistryAnalystProfile analyst = MinistryAnalystProfile(
    firebaseUid: 'DEMO-ANALYST-UID',
    analystId: 'ANALYST-001',
    organizationId: organizationId,
    displayLabel: 'Demo Ministry Analyst',
    role: AnalystRole.ministryAnalyst,
    isDemo: true,
  );

  static const MinistryAnalystProfile healthAdministrator =
      MinistryAnalystProfile(
    firebaseUid: 'DEMO-ANALYST-UID',
    analystId: 'ANALYST-002',
    organizationId: organizationId,
    displayLabel: 'Demo National Health Administrator',
    role: AnalystRole.nationalHealthAdministrator,
    isDemo: true,
  );

  static const MinistryAnalystProfile operationsAnalyst =
      MinistryAnalystProfile(
    firebaseUid: 'DEMO-ANALYST-UID',
    analystId: 'ANALYST-003',
    organizationId: organizationId,
    displayLabel: 'Demo National Operations Analyst',
    role: AnalystRole.nationalOperationsAnalyst,
    isDemo: true,
  );

  static MinistryAnalystProfile forRole(AnalystRole role) {
    switch (role) {
      case AnalystRole.ministryAnalyst:
        return analyst;
      case AnalystRole.nationalHealthAdministrator:
        return healthAdministrator;
      case AnalystRole.nationalOperationsAnalyst:
        return operationsAnalyst;
    }
  }
}
