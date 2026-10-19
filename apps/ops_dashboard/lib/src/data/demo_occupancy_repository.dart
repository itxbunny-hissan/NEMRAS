import 'occupancy_models.dart';

/// A deterministic demo occupancy model.
///
/// There is no bed telemetry behind this. `Room_Number` exists as a column in
/// `NEMRAS_Dataset.csv`, but it is a per-record string with no state, no
/// timestamp and no ward, and no backend route exposes it. A room is therefore
/// not something NEMRAS can currently observe, so this provider generates a
/// fixed estate purely so the occupancy screen has a shape to render.
///
/// The generator is seeded and deterministic, which keeps the demo stable
/// across restarts and makes the occupancy tests exact rather than
/// approximate.
class DemoOccupancyRepository implements OccupancyRepository {
  DemoOccupancyRepository({DateTime? capturedAt})
      : _capturedAt = (capturedAt ?? DateTime.now()).toUtc();

  final DateTime _capturedAt;

  /// Ward name, room count, and how many of those rooms are occupied.
  ///
  /// Ward names are generic department names, not a real hospital's floor
  /// plan. Counts are chosen to exercise the UI: Emergency sits above the
  /// pressure threshold, Surgery has a closed room, Maternity is quiet.
  static const List<({String ward, int rooms, int occupied, int closed})>
      _plan = <({String ward, int rooms, int occupied, int closed})>[
    (ward: 'Emergency', rooms: 24, occupied: 23, closed: 0),
    (ward: 'Cardiac ICU', rooms: 16, occupied: 13, closed: 0),
    (ward: 'General Medicine', rooms: 40, occupied: 29, closed: 0),
    (ward: 'Pediatrics', rooms: 20, occupied: 11, closed: 0),
    (ward: 'Maternity', rooms: 18, occupied: 9, closed: 0),
    (ward: 'Surgery', rooms: 22, occupied: 15, closed: 2),
  ];

  @override
  Future<OccupancySnapshot> fetchOccupancy({
    required String hospitalId,
  }) async {
    final wards = <WardOccupancy>[];

    for (var wardIndex = 0; wardIndex < _plan.length; wardIndex++) {
      final entry = _plan[wardIndex];
      final rooms = <RoomOccupancy>[];

      for (var i = 0; i < entry.rooms; i++) {
        final RoomState state;
        if (i < entry.occupied) {
          state = RoomState.occupied;
        } else if (i >= entry.rooms - entry.closed) {
          state = RoomState.closed;
        } else if ((i - entry.occupied) == 0 && entry.rooms > entry.occupied) {
          // One room per ward sits in turnover, so the UI always has a third
          // state to render rather than only occupied/available.
          state = RoomState.cleaning;
        } else {
          state = RoomState.available;
        }

        rooms.add(
          RoomOccupancy(
            // Mirrors the dataset's Room_Number formatting: a floor-derived
            // prefix and a two-digit room.
            roomNumber: '${(wardIndex + 1) * 100 + i + 1}',
            ward: entry.ward,
            state: state,
            isDemo: true,
          ),
        );
      }

      wards.add(
        WardOccupancy(ward: entry.ward, rooms: rooms, isDemo: true),
      );
    }

    return OccupancySnapshot(
      wards: wards,
      capturedAt: _capturedAt,
      isDemo: true,
    );
  }
}
