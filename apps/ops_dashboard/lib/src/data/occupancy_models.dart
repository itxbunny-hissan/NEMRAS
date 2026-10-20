import 'package:flutter/foundation.dart';

/// What a room is doing, as far as the demo provider is concerned.
///
/// These are *not* observed states. NEMRAS has no bed-management system, no
/// admission-discharge-transfer feed and no room sensors, so nothing here is
/// measured.
enum RoomState { occupied, available, cleaning, closed }

extension RoomStateLabel on RoomState {
  String get label {
    switch (this) {
      case RoomState.occupied:
        return 'OCCUPIED';
      case RoomState.available:
        return 'AVAILABLE';
      case RoomState.cleaning:
        return 'TURNOVER';
      case RoomState.closed:
        return 'CLOSED';
    }
  }

  /// True when the room cannot take a patient right now.
  bool get isUnavailable => this != RoomState.available;
}

/// A single room in the demo occupancy model.
@immutable
class RoomOccupancy {
  const RoomOccupancy({
    required this.roomNumber,
    required this.ward,
    required this.state,
    required this.isDemo,
  });

  /// Formatted like the dataset's `Room_Number` column so the demo stays
  /// recognisable, but it refers to no real room.
  final String roomNumber;
  final String ward;
  final RoomState state;
  final bool isDemo;
}

/// Occupancy for one ward.
@immutable
class WardOccupancy {
  const WardOccupancy({
    required this.ward,
    required this.rooms,
    required this.isDemo,
  });

  final String ward;
  final List<RoomOccupancy> rooms;
  final bool isDemo;

  int get total => rooms.length;
  int get occupied =>
      rooms.where((r) => r.state == RoomState.occupied).length;
  int get available =>
      rooms.where((r) => r.state == RoomState.available).length;
  int get turnover =>
      rooms.where((r) => r.state == RoomState.cleaning).length;
  int get closed => rooms.where((r) => r.state == RoomState.closed).length;

  /// Share of rooms that are occupied, 0 when the ward has no rooms.
  double get occupancyFraction =>
      total <= 0 ? 0 : (occupied / total).clamp(0.0, 1.0);

  String get occupancyPercentLabel =>
      '${(occupancyFraction * 100).round()}%';
}

/// The whole demo estate.
@immutable
class OccupancySnapshot {
  const OccupancySnapshot({
    required this.wards,
    required this.capturedAt,
    required this.isDemo,
  });

  final List<WardOccupancy> wards;

  /// When the demo state was generated, in UTC.
  final DateTime capturedAt;
  final bool isDemo;

  int get totalRooms =>
      wards.fold(0, (sum, ward) => sum + ward.total);
  int get occupiedRooms =>
      wards.fold(0, (sum, ward) => sum + ward.occupied);
  int get availableRooms =>
      wards.fold(0, (sum, ward) => sum + ward.available);
  int get turnoverRooms =>
      wards.fold(0, (sum, ward) => sum + ward.turnover);
  int get closedRooms => wards.fold(0, (sum, ward) => sum + ward.closed);

  double get occupancyFraction =>
      totalRooms <= 0 ? 0 : (occupiedRooms / totalRooms).clamp(0.0, 1.0);

  /// Wards at or above [threshold] occupancy, busiest first. Used to raise
  /// the pressure alert rather than hard-coding a ward name.
  List<WardOccupancy> wardsUnderPressure({double threshold = 0.9}) {
    final pressured = wards
        .where((w) => w.total > 0 && w.occupancyFraction >= threshold)
        .toList()
      ..sort(
        (a, b) => b.occupancyFraction.compareTo(a.occupancyFraction),
      );
    return pressured;
  }
}

/// The read boundary for room occupancy.
///
/// Phase 4A ships only a demo implementation. A real one would sit in front of
/// a bed-management or ADT system, which NEMRAS does not have.
abstract interface class OccupancyRepository {
  Future<OccupancySnapshot> fetchOccupancy({required String hospitalId});
}
