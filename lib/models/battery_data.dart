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
    voltage: 0.0,
    current: 0.0,
    temperature: 0.0,
  );

  double get power => voltage * current;
}
