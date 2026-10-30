/** Immutable light and motion values; null means unavailable. */
class SensorReading {
  /** Stores the current readings without inventing missing values. */
  const SensorReading(this.lux, this.stable);
  final double? lux;
  final bool? stable;
}
