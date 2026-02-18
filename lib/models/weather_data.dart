class WeatherData {
  final DateTime date;
  final double temperature;
  final double humidity;
  final double windSpeed;
  final String condition;
  final double rainProbability;
  final double rainAmount;

  WeatherData({
    required this.date,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.condition,
    required this.rainProbability,
    required this.rainAmount,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      date: DateTime.parse(json['date']),
      temperature: json['temperature'].toDouble(),
      humidity: json['humidity'].toDouble(),
      windSpeed: json['windSpeed'].toDouble(),
      condition: json['condition'],
      rainProbability: json['rainProbability'].toDouble(),
      rainAmount: json['rainAmount'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'temperature': temperature,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'condition': condition,
      'rainProbability': rainProbability,
      'rainAmount': rainAmount,
    };
  }
} 