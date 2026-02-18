class SensorData {
  final DateTime timestamp;
  final double soilMoisture;
  final double airTemperature;
  final double airHumidity;
  final double waterLevel;

  SensorData({
    required this.timestamp,
    required this.soilMoisture,
    required this.airTemperature,
    required this.airHumidity,
    required this.waterLevel,
  });
} 