class IrrigationAlert {
  final DateTime timestamp;
  final List<String> messages;
  final bool isPumpActive;
  final Map<String, dynamic> sensorData;

  IrrigationAlert({
    required this.timestamp,
    required this.messages,
    required this.isPumpActive,
    required this.sensorData,
  });

  factory IrrigationAlert.fromJson(Map<String, dynamic> json) {
    return IrrigationAlert(
      timestamp: DateTime.parse(json['timestamp']),
      messages: List<String>.from(json['messages']),
      isPumpActive: json['isPumpActive'],
      sensorData: Map<String, dynamic>.from(json['sensorData']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'messages': messages,
      'isPumpActive': isPumpActive,
      'sensorData': sensorData,
    };
  }

  String get formattedMessages {
    String result = '';
    if (isPumpActive) {
      result += '🚿 Pompe activée\n';
    }
    result += '📢 Alertes :\n';
    for (var message in messages) {
      result += '$message\n';
    }
    return result.trim();
  }
}
