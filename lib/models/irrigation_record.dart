class IrrigationRecord {
  final String id;
  final String configId;
  final DateTime date;
  final DateTime? endTime;
  final double waterVolume;
  final int duration;
  final String zone;
  final double soilMoisture;
  final String status; // 'completed', 'failed', 'in_progress'

  IrrigationRecord({
    required this.id,
    required this.configId,
    required this.date,
    this.endTime,
    required this.waterVolume,
    required this.duration,
    required this.zone,
    required this.soilMoisture,
    required this.status,
  });

  factory IrrigationRecord.fromJson(Map<String, dynamic> json) {
    return IrrigationRecord(
      id: json['id'],
      configId: json['configId'],
      date: DateTime.parse(json['date']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      waterVolume: json['waterVolume'].toDouble(),
      duration: json['duration'],
      zone: json['zone'],
      soilMoisture: json['soilMoisture'].toDouble(),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'configId': configId,
      'date': date.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'waterVolume': waterVolume,
      'duration': duration,
      'zone': zone,
      'soilMoisture': soilMoisture,
      'status': status,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'configId': configId,
      'startTime': date.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'waterVolume': waterVolume,
      'duration': duration,
      'zone': zone,
      'soilMoisture': soilMoisture,
      'status': status,
    };
  }

  factory IrrigationRecord.fromMap(Map<String, dynamic> map) {
    return IrrigationRecord(
      id: map['id'],
      configId: map['configId'],
      date: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      waterVolume: map['waterVolume'].toDouble(),
      duration: map['duration'],
      zone: map['zone'],
      soilMoisture: map['soilMoisture'].toDouble(),
      status: map['status'],
    );
  }
}
