/** One reading of the phone position. It is only compared with the campuses and never stored. */
class PositionReading {
  /** Stores coordinates and their accuracy. */
  const PositionReading({
    required this.lat,
    required this.lng,
    required this.accuracy,
  });
  final double lat;
  final double lng;
  final double accuracy;
}
