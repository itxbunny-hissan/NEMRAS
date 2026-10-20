import 'package:flutter/material.dart';

/// Honest status marks used across the portfolio. A demo or planned
/// capability is never labelled implemented.
enum PortfolioMark {
  implemented('Implemented'),
  demo('Demo'),
  ruleBased('Demo / rule-based'),
  partial('Partial'),
  planned('Planned'),
  current('Current'),
  proposed('Proposed');

  const PortfolioMark(this.label);

  final String label;
}

enum PortfolioSection {
  hero('Hero'),
  problem('Problem'),
  architecture('Architecture'),
  surfaces('Surfaces'),
  intelligence('Intelligence'),
  security('Security'),
  data('Data'),
  technology('Technology'),
  showcase('Showcase'),
  status('Status'),
  team('Team');

  const PortfolioSection(this.navLabel);

  final String navLabel;

  String get number => (index + 1).toString().padLeft(2, '0');
}

class ArchitectureLayer {
  const ArchitectureLayer({
    required this.title,
    required this.mark,
    required this.summary,
  });

  final String title;
  final PortfolioMark mark;
  final String summary;
}

class SurfaceProfile {
  const SurfaceProfile({
    required this.name,
    required this.purpose,
    required this.destinations,
    required this.mark,
    required this.state,
    required this.icon,
  });

  final String name;
  final String purpose;
  final List<String> destinations;
  final PortfolioMark mark;
  final String state;
  final IconData icon;
}

class CapabilityCard {
  const CapabilityCard({
    required this.name,
    required this.mark,
    required this.detail,
  });

  final String name;
  final PortfolioMark mark;
  final String detail;
}

class ClaimPoint {
  const ClaimPoint({required this.title, required this.detail});

  final String title;
  final String detail;
}

class StatusGroup {
  const StatusGroup({required this.mark, required this.entries});

  final PortfolioMark mark;
  final List<ClaimPoint> entries;
}

class ShowcaseFrame {
  const ShowcaseFrame({
    required this.surface,
    required this.mark,
    required this.destinations,
    required this.field,
  });

  final String surface;
  final PortfolioMark mark;
  final List<String> destinations;
  final bool field;
}

class PortfolioPerson {
  const PortfolioPerson({
    required this.name,
    required this.responsibility,
    this.asset,
  });

  final String name;

  /// Only "Team" or "Supervisor". No role title is recorded.
  final String responsibility;
  final String? asset;

  String get initials {
    final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

abstract final class PortfolioCopy {
  static const String productName = 'NEMRAS';
  static const String subtitle =
      'National Emergency Medical Record Access System';
  static const String context =
      'AI-driven emergency medical record access for the Pakistan healthcare context.';
  static const String heroBoundary =
      'FYP demo. This build combines implemented record access with rule-based and demo intelligence. Trained ML, an LLM, and RAG remain planned.';
  static const String demoMark = 'FYP DEMO';
  static const String deploymentMark = 'NOT A PRODUCTION DEPLOYMENT';
  static const String programme = 'BS Data Science, Batch 2023–2027';
  static const String datasetRows = '64,182';

  static const List<ArchitectureLayer> architecture = <ArchitectureLayer>[
    ArchitectureLayer(
      title: 'Flutter clients',
      mark: PortfolioMark.demo,
      summary:
          'Patient, paramedic, hospital clinical, hospital operations, national, and this portfolio. The screens are built. Identity and clinical values in the demos are not a live service.',
    ),
    ArchitectureLayer(
      title: 'FastAPI API Gateway / Identity',
      mark: PortfolioMark.demo,
      summary:
          'The API serves the dataset today. GET /api/v1/me/identity verifies a Firebase ID token. The other dataset routes are still unauthenticated.',
    ),
    ArchitectureLayer(
      title: 'Intelligence services',
      mark: PortfolioMark.demo,
      summary:
          'Alerts and the assistant are rule-based. A trained risk model, RAG, and an LLM are proposed and are not running.',
    ),
    ArchitectureLayer(
      title: 'Federated data plane',
      mark: PortfolioMark.proposed,
      summary:
          'No node agents, event stream, cache, national index, or FHIR store exists. Federation figures in the national demo are generated locally.',
    ),
    ArchitectureLayer(
      title: 'Governance / audit',
      mark: PortfolioMark.demo,
      summary:
          'Break-glass in the hospital demo records a justification for the session. Audit trails in the demos are in memory. A durable audit trail is proposed.',
    ),
  ];

  static const List<SurfaceProfile> surfaces = <SurfaceProfile>[
    SurfaceProfile(
      name: 'Patient / Paramedic',
      purpose:
          'A mobile clinical surface for a critical summary, and a dark field surface for an emergency session.',
      destinations: <String>[
        'Home, record timeline, health assistant, profile',
        'Paramedic scan, summary, drugs, handover, voice and notes',
      ],
      mark: PortfolioMark.demo,
      state:
          'Screens are built. Sign-in uses a fixed demo OTP. The assistant is keyword matching. Voice is a local visualization with no speech service.',
      icon: Icons.health_and_safety_outlined,
    ),
    SurfaceProfile(
      name: 'Hospital Clinical',
      purpose:
          'A desktop workspace for search, the open record, medication safety, handover, and a recorded emergency justification.',
      destinations: <String>[
        'Overview, emergency queue, patients, clinical records',
        'AI assistant, medications, handover, audit, settings',
      ],
      mark: PortfolioMark.demo,
      state:
          'The assistant reuses the rule-based backend responder and says it is not an LLM and not RAG. Break-glass keeps a justification in the session.',
      icon: Icons.local_hospital_outlined,
    ),
    SurfaceProfile(
      name: 'Hospital Operations',
      purpose:
          'An operational view of flow, beds, departments, compliance, and the demo audit trail.',
      destinations: <String>[
        'Overview, emergency, bed occupancy, patients, departments',
        'Reports, compliance, audit trail, settings',
      ],
      mark: PortfolioMark.demo,
      state:
          'Figures are marked dataset-derived, dataset-sample, or demo. This surface does not open a patient record.',
      icon: Icons.apartment_outlined,
    ),
    SurfaceProfile(
      name: 'National / Ministry',
      purpose:
          'An aggregate console for emergency trends, indicators, the hospital network, federation, and governance.',
      destinations: <String>[
        'National overview, emergency trends, health indicators',
        'Hospital network, federation, reports, audit / governance, settings',
      ],
      mark: PortfolioMark.demo,
      state:
          'Reads are reduced to aggregates. Names and CNICs are not shown. Regional maps were not built, because the dataset has no geography. Federation numbers are generated locally.',
      icon: Icons.account_balance_outlined,
    ),
    SurfaceProfile(
      name: 'Portfolio',
      purpose:
          'This case study. It explains the four product surfaces and the boundary between what runs and what is still proposed.',
      destinations: <String>[
        'Hero, problem, architecture, surfaces, intelligence',
        'Security, data, technology, showcase, status, team',
      ],
      mark: PortfolioMark.implemented,
      state:
          'A Flutter Web surface on the shared NEMRAS design system. It is not a deployed public service.',
      icon: Icons.web_outlined,
    ),
  ];

  static const List<CapabilityCard> intelligence = <CapabilityCard>[
    CapabilityCard(
      name: 'Risk score',
      mark: PortfolioMark.demo,
      detail:
          'The screen displays the dataset Risk_Score field. No model is trained or executed at runtime.',
    ),
    CapabilityCard(
      name: 'Drug interaction / safety',
      mark: PortfolioMark.ruleBased,
      detail:
          'Point-of-care alerts are rules over Allergy, Drug_Interaction_Risk, Risk_Score, and Chronic_Condition.',
    ),
    CapabilityCard(
      name: 'Clinical / health assistant',
      mark: PortfolioMark.ruleBased,
      detail:
          'A deterministic keyword responder over the one open record. It is not an LLM and not RAG, and it is not clinically validated.',
    ),
    CapabilityCard(
      name: 'Paramedic voice',
      mark: PortfolioMark.demo,
      detail:
          'Local visualization and notes on the field surface. No speech service.',
    ),
  ];

  static const List<CapabilityCard> plannedIntelligence = <CapabilityCard>[
    CapabilityCard(
      name: 'Trained risk model',
      mark: PortfolioMark.planned,
      detail: 'Not trained and not called from the API.',
    ),
    CapabilityCard(
      name: 'RAG',
      mark: PortfolioMark.planned,
      detail: 'Not built. The current assistant is not RAG.',
    ),
    CapabilityCard(
      name: 'LLM',
      mark: PortfolioMark.planned,
      detail: 'Not built. The current assistant is not an LLM.',
    ),
  ];

  static const List<ClaimPoint> security = <ClaimPoint>[
    ClaimPoint(
      title: 'Firebase identity layer',
      detail:
          'The patient app depends on Firebase Auth. The backend verifies a Firebase ID token with the Admin SDK on one route.',
    ),
    ClaimPoint(
      title: 'Firebase UID is not a CNIC',
      detail:
          'CNIC is the patient identifier. The Firebase UID is the identity identifier. They are not the same value.',
    ),
    ClaimPoint(
      title: 'Authenticated identity route',
      detail:
          'GET /api/v1/me/identity checks the token and returns the verified UID. It does not open a record.',
    ),
    ClaimPoint(
      title: 'Dataset routes are a known demo limit',
      detail:
          'Unversioned dataset routes do not require a token. The Flutter UI is not the security boundary.',
    ),
    ClaimPoint(
      title: 'Break-glass justification',
      detail:
          'The hospital demo asks for a reason and keeps it on the session. It is not a production override workflow.',
    ),
    ClaimPoint(
      title: 'In-memory audit',
      detail:
          'Hospital, operations, and national trails live for the session and are lost on reload. The patient audit screen is a static illustration.',
    ),
    ClaimPoint(
      title: 'National aggregate boundary',
      detail:
          'The national surface uses aggregate information. It does not render raw patient identifiers.',
    ),
    ClaimPoint(
      title: 'Proposed production boundary',
      detail:
          'Server-side authorisation on every record route, a connected UID-to-CNIC binding, and a durable audit trail are not built yet.',
    ),
  ];

  static const List<ClaimPoint> dataPoints = <ClaimPoint>[
    ClaimPoint(
      title: 'Read-only dataset',
      detail:
          'The backend loads NEMRAS_Dataset.csv. This portfolio does not read or modify that file.',
    ),
    ClaimPoint(
      title: 'Synthetic demo data',
      detail:
          'The rows support the FYP demo. They are not a live register and this page does not reproduce them.',
    ),
    ClaimPoint(
      title: 'CNIC lookup stays in the apps',
      detail:
          'Patient lookup is CNIC-based in the API. No CNIC, name, or phone number is shown here.',
    ),
    ClaimPoint(
      title: 'National views stay aggregate',
      detail:
          'Where a patient-level response exists, the national app reduces it before display.',
    ),
  ];

  static const List<String> currentTechnology = <String>[
    'Flutter',
    'Dart',
    'FastAPI',
    'Python',
    'Firebase Auth',
    'Firebase Admin',
    'SQLite identity foundation',
    'CSV dataset',
  ];

  static const List<String> proposedTechnology = <String>[
    'Trained ML risk model',
    'RAG',
    'Durable audit',
    'Full authorization on record routes',
    'Federated infrastructure',
  ];

  static const List<ShowcaseFrame> showcase = <ShowcaseFrame>[
    ShowcaseFrame(
      surface: 'Patient',
      mark: PortfolioMark.demo,
      destinations: <String>['Home', 'Record', 'Assistant', 'Profile'],
      field: false,
    ),
    ShowcaseFrame(
      surface: 'Paramedic',
      mark: PortfolioMark.demo,
      destinations: <String>['Scan', 'Summary', 'Drugs', 'Voice'],
      field: true,
    ),
    ShowcaseFrame(
      surface: 'Hospital Clinical',
      mark: PortfolioMark.demo,
      destinations: <String>['Queue', 'Patients', 'Record', 'Audit'],
      field: false,
    ),
    ShowcaseFrame(
      surface: 'Hospital Operations',
      mark: PortfolioMark.demo,
      destinations: <String>['Flow', 'Beds', 'Compliance', 'Audit'],
      field: false,
    ),
    ShowcaseFrame(
      surface: 'National / Ministry',
      mark: PortfolioMark.demo,
      destinations: <String>['Overview', 'Trends', 'Network', 'Governance'],
      field: false,
    ),
  ];

  static const List<StatusGroup> status = <StatusGroup>[
    StatusGroup(
      mark: PortfolioMark.implemented,
      entries: <ClaimPoint>[
        ClaimPoint(
          title: 'CNIC lookup and critical summary',
          detail: 'Reads the bundled dataset through the FastAPI patient route.',
        ),
        ClaimPoint(
          title: 'Barcode scanning',
          detail: 'The patient app can read a CNIC barcode.',
        ),
        ClaimPoint(
          title: 'Population statistics',
          detail: 'Live counts and the critical-patient feed from the dataset.',
        ),
        ClaimPoint(
          title: 'Masked phone lookup',
          detail: 'The phone route returns a hint, not a raw number.',
        ),
        ClaimPoint(
          title: 'Product surfaces',
          detail:
              'Patient, paramedic, hospital clinical, hospital operations, and national apps are built.',
        ),
      ],
    ),
    StatusGroup(
      mark: PortfolioMark.ruleBased,
      entries: <ClaimPoint>[
        ClaimPoint(
          title: 'Risk score',
          detail: 'Displays the dataset Risk_Score field. No trained model runs.',
        ),
        ClaimPoint(
          title: 'Drug-interaction alerts',
          detail: 'Rules over recorded allergy, interaction, risk, and condition fields.',
        ),
        ClaimPoint(
          title: 'Health assistant',
          detail: 'Keyword matching. Not an LLM and not RAG.',
        ),
        ClaimPoint(
          title: 'Paramedic voice',
          detail: 'Local visualization and notes. No speech service.',
        ),
        ClaimPoint(
          title: 'Sign-in, audit, and federation figures',
          detail:
              'Demo OTP, in-memory trails, break-glass justification, and locally generated federation figures.',
        ),
      ],
    ),
    StatusGroup(
      mark: PortfolioMark.partial,
      entries: <ClaimPoint>[
        ClaimPoint(
          title: 'Firebase token check',
          detail: 'Only GET /api/v1/me/identity verifies a caller.',
        ),
        ClaimPoint(
          title: 'UID-to-CNIC store',
          detail:
              'The SQLite binding module exists and is not connected to a route.',
        ),
      ],
    ),
    StatusGroup(
      mark: PortfolioMark.planned,
      entries: <ClaimPoint>[
        ClaimPoint(
          title: 'Trained risk model',
          detail: 'Not trained and not called from the API.',
        ),
        ClaimPoint(
          title: 'RAG / LLM assistant',
          detail: 'Not built. The current responder stays rule-based.',
        ),
        ClaimPoint(
          title: 'Durable audit and full authorization',
          detail: 'Record routes are not yet authorised or durably audited.',
        ),
        ClaimPoint(
          title: 'Federated infrastructure',
          detail: 'Described by the national demo as absent.',
        ),
      ],
    ),
  ];

  static const List<PortfolioPerson> team = <PortfolioPerson>[
    PortfolioPerson(name: 'Kashaf Sajjad', responsibility: 'Team'),
    PortfolioPerson(
      name: 'Mirza Hissan Baig',
      responsibility: 'Team',
      asset: 'assets/team/mirza_hissan_baig.jpg',
    ),
    PortfolioPerson(name: 'Azka Ashraf', responsibility: 'Team'),
  ];

  static const PortfolioPerson supervisor = PortfolioPerson(
    name: 'Muhammad Manshah',
    responsibility: 'Supervisor',
    asset: 'assets/team/muhammad_manshah.jpg',
  );

  static const List<ClaimPoint> problem = <ClaimPoint>[
    ClaimPoint(
      title: 'Fragmented records',
      detail:
          'In an emergency, the context a clinician needs may sit in another hospital’s system and not be at the bedside.',
    ),
    ClaimPoint(
      title: 'Rapid critical context',
      detail:
          'NEMRAS is aimed at a short summary: who the person is, and the allergies, conditions, and recorded risk that change the next decision.',
    ),
    ClaimPoint(
      title: 'Emergency decision support',
      detail:
          'The current demo surfaces rule-based alerts from fields already in the dataset. It does not replace a clinician.',
    ),
    ClaimPoint(
      title: 'Privacy and governance',
      detail:
          'A national view has to stay aggregate. Emergency access needs a reason, and that access has to be auditable.',
    ),
  ];
}
