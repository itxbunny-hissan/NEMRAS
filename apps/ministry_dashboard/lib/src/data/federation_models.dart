import 'package:flutter/foundation.dart';

/// The health state of a federated node.
///
/// These are *not* observed states. NEMRAS has no node agents, no
/// synchronisation protocol, no message broker and no national index, so
/// nothing in this file is measured.
enum NodeHealth { online, degraded, offline }

extension NodeHealthLabel on NodeHealth {
  String get label {
    switch (this) {
      case NodeHealth.online:
        return 'ONLINE';
      case NodeHealth.degraded:
        return 'DEGRADED';
      case NodeHealth.offline:
        return 'OFFLINE';
    }
  }

  String get meaning {
    switch (this) {
      case NodeHealth.online:
        return 'Simulated node reporting normal synchronisation.';
      case NodeHealth.degraded:
        return 'Simulated node reporting delayed synchronisation.';
      case NodeHealth.offline:
        return 'Simulated node not reporting.';
    }
  }

  bool get needsAttention => this != NodeHealth.online;
}

/// One federated node in the demo federation model.
///
/// Fields are exactly those the brief specifies. There is deliberately no
/// province, city or coordinate field and no latency field: a province would
/// be fabricated geography, and a latency would be fabricated telemetry.
@immutable
class FederationNode {
  const FederationNode({
    required this.nodeId,
    required this.hospitalId,
    required this.health,
    required this.lastSynchronizedAt,
    required this.recordsSynchronized,
    required this.isDemo,
  });

  /// `NMR-NNN`, matching the reference's node identifier format.
  final String nodeId;

  /// The NEMRAS hospital identifier this node would serve. `HOSP-001` is the
  /// same demo identifier the hospital surfaces use.
  final String hospitalId;

  final NodeHealth health;

  /// UTC. Simulated, not observed.
  final DateTime lastSynchronizedAt;

  /// A simulated cumulative count of records this node would have pushed.
  final int recordsSynchronized;

  /// True for every Phase 5A node. The UI must surface this.
  final bool isDemo;

  /// How long since the simulated node last synchronised.
  ///
  /// [now] is passed in rather than read from the clock so the value is
  /// deterministic in tests and no widget holds a ticking timer.
  Duration staleness(DateTime now) {
    final elapsed = now.toUtc().difference(lastSynchronizedAt);
    return elapsed.isNegative ? Duration.zero : elapsed;
  }

  String stalenessLabel(DateTime now) {
    final elapsed = staleness(now);
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m ago';
    if (elapsed.inHours < 24) return '${elapsed.inHours}h ago';
    return '${elapsed.inDays}d ago';
  }
}

/// Counts by node health, for the federation header and the overview panel.
@immutable
class FederationTally {
  const FederationTally({
    required this.online,
    required this.degraded,
    required this.offline,
    required this.recordsSynchronized,
    required this.isDemo,
  });

  factory FederationTally.from(
    List<FederationNode> nodes, {
    required bool isDemo,
  }) {
    int count(NodeHealth health) =>
        nodes.where((node) => node.health == health).length;
    return FederationTally(
      online: count(NodeHealth.online),
      degraded: count(NodeHealth.degraded),
      offline: count(NodeHealth.offline),
      recordsSynchronized: nodes.fold(
        0,
        (sum, node) => sum + node.recordsSynchronized,
      ),
      isDemo: isDemo,
    );
  }

  final int online;
  final int degraded;
  final int offline;
  final int recordsSynchronized;
  final bool isDemo;

  int get total => online + degraded + offline;

  int get needingAttention => degraded + offline;

  /// Share of simulated nodes reporting normally.
  double get onlineFraction =>
      total <= 0 ? 0 : (online / total).clamp(0.0, 1.0);

  String get onlinePercentLabel =>
      total <= 0 ? 'Not available' : '${(onlineFraction * 100).round()}%';
}

/// The whole demo federation.
@immutable
class FederationSnapshot {
  const FederationSnapshot({
    required this.nodes,
    required this.capturedAt,
    required this.isDemo,
  });

  final List<FederationNode> nodes;

  /// When the demo state was generated, in UTC.
  final DateTime capturedAt;
  final bool isDemo;

  FederationTally get tally => FederationTally.from(nodes, isDemo: isDemo);

  /// Nodes needing attention, worst state first, then stalest.
  List<FederationNode> nodesNeedingAttention(DateTime now) {
    final flagged =
        nodes.where((node) => node.health.needsAttention).toList()
          ..sort((a, b) {
            final byHealth =
                b.health.index.compareTo(a.health.index);
            if (byHealth != 0) return byHealth;
            return b.staleness(now).compareTo(a.staleness(now));
          });
    return flagged;
  }
}

/// The read boundary for federation state.
///
/// Phase 5A ships only a demo implementation. The interface is shaped so a
/// future transport — node agents reporting over an event stream, a national
/// index, or a FHIR store's sync log — can serve it without any screen
/// changing. None of those exists, and this phase builds none of them.
abstract interface class FederationRepository {
  Future<FederationSnapshot> fetchFederation({required String organizationId});
}
