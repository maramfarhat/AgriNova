import 'package:flutter/foundation.dart';

class Weather {
  final double temperature;
  final String condition;
  final String iconUrl;
  final int humidity;
  final double windSpeed;
  final String windDirection;
  final double precipitation;

  Weather({
    required this.temperature,
    required this.condition,
    required this.iconUrl,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.precipitation,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    try {
      final mainData = json['main'] as Map<String, dynamic>? ?? {};
      final weatherData = (json['weather'] as List?)?.firstOrNull as Map<String, dynamic>? ?? {};
      final windData = json['wind'] as Map<String, dynamic>? ?? {};
      final rainData = json['rain'] as Map<String, dynamic>? ?? {};

      return Weather(
        temperature: (mainData['temp'] as num?)?.toDouble() ?? 0.0,
        condition: weatherData['description'] as String? ?? '',
        iconUrl: 'https://openweathermap.org/img/wn/${weatherData['icon'] ?? '01d'}@2x.png',
        humidity: (mainData['humidity'] as num?)?.toInt() ?? 0,
        windSpeed: (windData['speed'] as num?)?.toDouble() ?? 0.0,
        windDirection: _getWindDirection((windData['deg'] as num?)?.toInt() ?? 0),
        precipitation: (rainData['1h'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (e) {
      debugPrint('Error parsing weather data: $e');
      return Weather(
        temperature: 0.0,
        condition: 'Erreur de données',
        iconUrl: 'https://openweathermap.org/img/wn/01d@2x.png',
        humidity: 0,
        windSpeed: 0.0,
        windDirection: 'N/A',
        precipitation: 0.0,
      );
    }
  }

  static String _getWindDirection(int degrees) {
    final directions = ['N', 'NE', 'E', 'SE', 'S', 'SO', 'O', 'NO'];
    final index = ((degrees + 22.5) % 360) ~/ 45;
    return directions[index];
  }
}