class BatteryData {
  final double voltage;
  final double current;
  final double temperature;

  const BatteryData({
    required this.voltage,
    required this.current,
    required this.temperature,
  });

  static const empty = BatteryData(
    voltage: 0,
    current: 0,
    temperature: 0,
  );

  double get power => voltage * current;

  BatteryData copyWith({
    double? voltage,
    double? current,
    double? temperature,
  }) {
    return BatteryData(
      voltage: voltage ?? this.voltage,
      current: current ?? this.current,
      temperature: temperature ?? this.temperature,
    );
  }
}