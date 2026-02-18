import 'package:flutter/foundation.dart';

class WeatherForecast {
  final DateTime date;
  final double temperature;
  final String condition;
  final String iconUrl;
  final int humidity;

  WeatherForecast({
    required this.date,
    required this.temperature,
    required this.condition,
    required this.iconUrl,
    required this.humidity,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    try {
      final dt = json['dt'] as int? ?? 0;
      final temp = (json['temp'] as Map<String, dynamic>?)?.cast<String, dynamic>() ?? {};
      final weather = (json['weather'] as List?)?.firstOrNull as Map<String, dynamic>? ?? {};

      return WeatherForecast(
        date: DateTime.fromMillisecondsSinceEpoch((dt * 1000)),
        temperature: (temp['day'] as num?)?.toDouble() ?? 0.0,
        condition: weather['description'] as String? ?? '',
        iconUrl: 'https://openweathermap.org/img/wn/${weather['icon'] ?? '01d'}@2x.png',
        humidity: (json['humidity'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      debugPrint('Error parsing weather forecast: $e');
      return WeatherForecast(
        date: DateTime.now(),
        temperature: 0.0,
        condition: 'Erreur de données',
        iconUrl: 'https://openweathermap.org/img/wn/01d@2x.png',
        humidity: 0,
      );
    }
  }
} 