class IoTData {
  final double airTemperature;
  final double airHumidity;
  final double? soilMoisture;
  final double? lightLevel;
  final double? waterLevel;
  final bool flameDetected;
  final double? phValue;
  final bool phImmersed;
  final DateTime timestamp;

  IoTData({
    required this.airTemperature,
    required this.airHumidity,
    this.soilMoisture,
    this.lightLevel,
    this.waterLevel,
    required this.flameDetected,
    this.phValue,
    required this.phImmersed,
    required this.timestamp,
  });

  factory IoTData.fromJson(Map<String, dynamic> json) {
    var phValue = json['ph_value'];
    return IoTData(
      airTemperature: json['temperature']?.toDouble() ?? 0.0,
      airHumidity: json['humidity']?.toDouble() ?? 0.0,
      soilMoisture: json['soil_moisture_percent']?.toDouble(),
      lightLevel: json['lightLevel']?.toDouble(),
      waterLevel: json['water_level_percent']?.toDouble(),
      flameDetected: json['flame_detected'] ?? false,
      phValue: phValue == "N/A" ? null : double.tryParse(phValue.toString()),
      phImmersed: json['ph_status'] == "immersed",
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'airTemperature': airTemperature,
      'airHumidity': airHumidity,
      'soilMoisture': soilMoisture,
      'lightLevel': lightLevel,
      'waterLevel': waterLevel,
      'flameDetected': flameDetected,
      'phValue': phValue,
      'phImmersed': phImmersed,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
